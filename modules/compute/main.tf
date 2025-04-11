resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  security_groups = [var.security_group_id]
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git python3-opencv
              pip3 install boto3 opencv-python-headless flask
              git clone https://github.com/joaolfms/contador-facial.git /home/ec2-user/event-counter
              cd /home/ec2-user/event-counter
              nohup python3 app.py &
              EOF

  tags = {
    Name = "EventCounter"
  }
}