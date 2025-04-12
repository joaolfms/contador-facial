import cv2
import boto3
import time
from botocore.exceptions import ClientError
from flask import Flask, jsonify, render_template, request
import threading
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Defina a região da AWS
REGION = 'us-east-1'

# Configurações AWS
rekognition = boto3.client('rekognition', region_name=REGION)
dynamodb = boto3.resource('dynamodb', region_name=REGION)

# Nome da tabela DynamoDB (deve corresponder ao Terraform)
TABLE_NAME = 'EventFaces'

# URL do stream DroidCam (HTTP/MJPEG)
RTSP_URL = 'http://10.8.0.6:4747/video'

# ID da coleção Rekognition (deve corresponder ao Terraform)
face_collection_id = 'EventFaces'

# Inicializar DynamoDB
table = dynamodb.Table(TABLE_NAME)

is_counting = False

def process_stream():
    global is_counting
    cap = cv2.VideoCapture(RTSP_URL)

    if not cap.isOpened():
        logger.error("Erro: Não foi possível abrir o stream de vídeo do DroidCam")
        return

    logger.info("Stream de vídeo aberto com sucesso")

    while is_counting and cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            logger.error("Erro ao capturar frame")
            time.sleep(1)
            continue

        # Converter frame para JPEG
        _, buffer = cv2.imencode('.jpg', frame)
        image_bytes = buffer.tobytes()

        # Detectar rostos com Rekognition
        try:
            response = rekognition.detect_faces(
                Image={'Bytes': image_bytes},
                Attributes=['ALL']
            )

            for face in response['FaceDetails']:
                # Tentar encontrar o rosto na coleção
                search_response = rekognition.search_faces_by_image(
                    CollectionId=face_collection_id,
                    Image={'Bytes': image_bytes},
                    MaxFaces=1,
                    FaceMatchThreshold=90
                )

                if search_response['FaceMatches']:
                    face_id = search_response['FaceMatches'][0]['Face']['FaceId']
                    logger.info(f"Rosto encontrado: {face_id}")
                else:
                    # Indexar novo rosto
                    index_response = rekognition.index_faces(
                        CollectionId=face_collection_id,
                        Image={'Bytes': image_bytes},
                        DetectionAttributes=['ALL']
                    )
                    if index_response['FaceRecords']:
                        face_id = index_response['FaceRecords'][0]['Face']['FaceId']
                        # Salvar no DynamoDB
                        table.put_item(
                            Item={
                                'FaceId': face_id,
                                'Timestamp': int(time.time())
                            }
                        )
                        logger.info(f"Novo rosto indexado e salvo: {face_id}")

        except ClientError as e:
            logger.error(f"Erro no Rekognition: {e}")
            time.sleep(1)
            continue

        # Aguardar antes de processar o próximo frame
        time.sleep(2)

    cap.release()
    logger.info("Stream de vídeo encerrado")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/control', methods=['POST'])
def control():
    global is_counting
    action = request.json.get('action')

    if action == 'start' and not is_counting:
        is_counting = True
        threading.Thread(target=process_stream, daemon=True).start()
        return jsonify({'message': 'Contagem iniciada'})
    
    elif action == 'stop' and is_counting:
        is_counting = False
        return jsonify({'message': 'Contagem parada'})
    
    return jsonify({'error': 'Ação inválida ou estado incorreto'}), 400

@app.route('/api/count', methods=['GET'])
def get_count():
    try:
        response = table.scan()
        count = len(response['Items'])
        return jsonify({'count': count})
    except ClientError as e:
        logger.error(f"Erro ao consultar DynamoDB: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)