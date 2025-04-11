# app.py
import cv2
import boto3
import time
from botocore.exceptions import ClientError
from flask import Flask, jsonify, render_template, request
import threading
import os

app = Flask(__name__)

# Configurações AWS
rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = 'EventFaces'  # Mesmo nome definido no Terraform
RTSP_URL = 'rtsp://192.168.1.6:4747/video'
is_counting = False
face_collection_id = 'EventFaces'

# Inicializar DynamoDB
table = dynamodb.Table(TABLE_NAME)

def process_stream():
    global is_counting
    cap = cv2.VideoCapture(RTSP_URL)

    while is_counting and cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Erro ao capturar frame")
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

        except ClientError as e:
            print(f"Erro no Rekognition: {e}")
            time.sleep(1)
            continue

        # Aguardar antes de processar o próximo frame
        time.sleep(2)  # Ajuste conforme necessário

    cap.release()

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
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Criar coleção Rekognition, se não existir
    try:
        rekognition.create_collection(CollectionId=face_collection_id)
    except rekognition.exceptions.ResourceAlreadyExistsException:
        pass

    app.run(host='0.0.0.0', port=80)