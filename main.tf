# terraform/main.tf
provider "aws" {
  region = "us-east-1"
}

# DynamoDB para armazenar IDs de rostos
resource "aws_dynamodb_table" "faces_table" {
  name           = "EventFaces"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "FaceId"

  attribute {
    name = "FaceId"
    type = "S"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "event-counter-sg"
  description = "Permite HTTP, RTSP e SSH do seu IP"

  # Regra para SSH apenas do seu IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["177.84.47.208/32"]  # Substitua por SEU IP público
  }

  # Regra para HTTP (acesso público)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para RTSP (acesso público)
  ingress {
    from_port   = 4747
    to_port     = 4747
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída liberada para todos
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role para a EC2
resource "aws_iam_role" "ec2_role" {
  name = "event_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectFaces",
          "rekognition:SearchFacesByImage",
          "rekognition:IndexFaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.faces_table.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "event_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "event_counter" {
  ami                    = "ami-0ebfd941bbafe70c6" # AMI x86_64 para Amazon Linux 2
  instance_type          = "t3.medium"
  security_groups        = [aws_security_group.ec2_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = "rufus"

  user_data = <<-EOF
            #!/bin/bash
            set -e
            yum update -y
            yum install -y python3 git
            pip3 install --user boto3 opencv-python-headless flask
            git clone https://github.com/joaolfms/contador-facial.git /home/ec2-user/event-counter || { echo "Falha ao clonar repositório"; exit 1; }
            cd /home/ec2-user/event-counter
            cat <<EOT > /etc/systemd/system/event-counter.service
            [Unit]
            Description=Event Counter Flask App
            After=network.target
            [Service]
            User=ec2-user
            WorkingDirectory=/home/ec2-user/event-counter
            ExecStart=/usr/bin/python3 /home/ec2-user/event-counter/app.py
            Restart=always
            [Install]
            WantedBy=multi-user.target
            EOT
            systemctl enable event-counter.service
            systemctl start event-counter.service
            EOF

  tags = {
    Name = "EventCounter"
  }
}

output "ec2_public_ip" {
  value = aws_instance.event_counter.public_ip
}