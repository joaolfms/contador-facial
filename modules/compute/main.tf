resource "aws_instance" "app" {
  ami           = "ami-00a929b66ed6e0de6"  # Amazon Linux 2
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  security_groups = [var.security_group_id]
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash

              # Criar um arquivo de log para depuração
              exec > /var/log/app-install.log 2>&1
              echo "Iniciando configuração da aplicação..."

              # Instalar dependências
              echo "Atualizando sistema e instalando pacotes..."
              dnf update -y
              dnf install -y python3 python3-pip git

              # Instalar bibliotecas Python
              echo "Instalando bibliotecas Python..."
              pip3 install boto3 opencv-python-headless flask || echo "Erro ao instalar bibliotecas Python"

              # Clonar o repositório
              echo "Clonando repositório event-counter..."
              git clone https://github.com/joaolfms/contador-facial.git /home/ec2-user/event-counter || echo "Erro ao clonar repositório"

              # Ajustar permissões
              echo "Ajustando permissões..."
              chown -R ec2-user:ec2-user /home/ec2-user/event-counter

              # Executar a aplicação
              echo "Iniciando aplicação..."
              cd /home/ec2-user/event-counter
              nohup python3 app.py &

              echo "Configuração da aplicação concluída!"
              EOF

  tags = {
    Name = "EventCounter"
  }
}

