import cv2
import boto3
import numpy as np
from datetime import datetime
import time
import logging
import csv
import os
import threading

# Configuração do logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler("contador.log"), logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Arquivo pra salvar os dados
OUTPUT_FILE = "entradas_evento.csv"

# Configurações de câmeras
CAMERAS = [
    {"url": "http://1:8080/video", "name": "Entrada Principal"},
]

# Cliente Rekognition
rekognition = boto3.client('rekognition')

class ContadorEventos:
    def __init__(self, camera_config):
        self.url = camera_config["url"]
        self.name = camera_config["name"]
        self.contador_pessoas = 0
        self.ultima_contagem = 0
        self.cooldown = 2.0  # Segundos entre contagens
        self.cap = None
        self.lock = threading.Lock()

        if not os.path.exists(OUTPUT_FILE):
            with open(OUTPUT_FILE, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(["ID", "Horário", "Total Acumulado", "Câmera"])

    def conectar_camera(self):
        self.cap = cv2.VideoCapture(self.url)
        if not self.cap.isOpened():
            logger.error(f"[{self.name}] Erro ao conectar à câmera.")
            return False
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.cap.set(cv2.CAP_PROP_FPS, 15)
        logger.info(f"[{self.name}] Câmera conectada.")
        return True

    def registrar_entrada(self, horario):
        with self.lock:
            self.contador_pessoas += 1
            total = self.contador_pessoas
            with open(OUTPUT_FILE, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([total, horario, total, self.name])
            logger.info(f"[{self.name}] Nova pessoa detectada! Total: {total} às {horario}")

    def processar_frame(self, frame):
        # Converte frame pra bytes pro Rekognition
        _, buffer = cv2.imencode('.jpg', frame)
        image_bytes = buffer.tobytes()

        # Chama a API DetectFaces
        response = rekognition.detect_faces(
            Image={'Bytes': image_bytes},
            Attributes=['DEFAULT']
        )

        # Conta rostos detectados
        faces = response['FaceDetails']
        current_time = time.time()
        if faces and (current_time - self.ultima_contagem > self.cooldown):
            self.ultima_contagem = current_time
            horario = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            self.registrar_entrada(horario)

    def run(self):
        if not self.conectar_camera():
            return

        frame_count = 0
        process_every_n_frames = 5
        logger.info(f"[{self.name}] Iniciando contagem...")

        while True:
            try:
                ret, frame = self.cap.read()
                if not ret:
                    logger.warning(f"[{self.name}] Erro ao capturar frame. Reconectando...")
                    self.cap.release()
                    if not self.conectar_camera():
                        break
                    continue

                frame_count += 1
                if frame_count % process_every_n_frames == 0:
                    self.processar_frame(frame)

            except Exception as e:
                logger.error(f"[{self.name}] Erro no processamento: {e}")
                time.sleep(5)

        self.cap.release()
        logger.info(f"[{self.name}] Total final: {self.contador_pessoas}")

def main():
    contadores = [ContadorEventos(camera) for camera in CAMERAS]
    threads = []

    for contador in contadores:
        t = threading.Thread(target=contador.run)
        t.start()
        threads.append(t)

    for t in threads:
        t.join()

if __name__ == "__main__":
    main()