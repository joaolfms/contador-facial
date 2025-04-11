# Usar uma imagem base do Python
FROM python:3.9-slim

# Definir o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copiar o arquivo de requisitos (se existir)
COPY requirements.txt .

# Instalar dependências do sistema e bibliotecas Python
RUN apt-get update && apt-get install -y \
    libopencv-dev \
    && pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação
COPY . .

# Expor a porta que a aplicação usa (exemplo: 5000 para Flask)
EXPOSE 5000

# Comando para rodar a aplicação
CMD ["python", "app.py"]