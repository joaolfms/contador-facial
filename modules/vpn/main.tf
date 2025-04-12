# modules/vpn/main.tf
resource "aws_instance" "openvpn" {
  ami           = "ami-00a929b66ed6e0de6"  # Amazon Linux 2 x86_64 (us-east-1)
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]
  associate_public_ip_address = true
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash

              # Criar um arquivo de log para depuração
              exec > /var/log/openvpn-install.log 2>&1
              echo "Iniciando configuração do OpenVPN..."

              # Instalar dependências
              echo "Atualizando sistema e instalando pacotes..."
              dnf update -y
              dnf install -y openvpn

              # Baixar e configurar o Easy-RSA manualmente
              echo "Baixando Easy-RSA..."
              dnf install -y wget tar
              wget -P /tmp https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz
              tar -xzf /tmp/EasyRSA-3.1.2.tgz -C /tmp
              mv /tmp/EasyRSA-3.1.2 /etc/openvpn/easy-rsa
              cd /etc/openvpn/easy-rsa

              # Inicializar o PKI
              echo "Inicializando PKI..."
              ./easyrsa init-pki || echo "Erro ao inicializar PKI"

              # Gerar CA
              echo "Gerando CA..."
              ./easyrsa --batch build-ca nopass || echo "Erro ao gerar CA"

              # Gerar certificado e chave do servidor
              echo "Gerando certificados do servidor..."
              ./easyrsa --batch build-server-full server nopass || echo "Erro ao gerar certificados do servidor"

              # Gerar certificado e chave do cliente (user1)
              echo "Gerando certificados do cliente user1..."
              ./easyrsa --batch build-client-full ${var.openvpn_users[0]} nopass || echo "Erro ao gerar certificados do cliente"

              # Gerar Diffie-Hellman
              echo "Gerando DH..."
              ./easyrsa gen-dh || echo "Erro ao gerar DH"

              # Copiar certificados para /etc/openvpn/ e ajustar permissões
              echo "Copiando certificados..."
              cp pki/ca.crt /etc/openvpn/ || echo "Erro ao copiar ca.crt"
              cp pki/issued/server.crt /etc/openvpn/ || echo "Erro ao copiar server.crt"
              cp pki/private/server.key /etc/openvpn/ || echo "Erro ao copiar server.key"
              cp pki/dh.pem /etc/openvpn/ || echo "Erro ao copiar dh.pem"
              cp pki/issued/${var.openvpn_users[0]}.crt /etc/openvpn/ || echo "Erro ao copiar ${var.openvpn_users[0]}.crt"
              cp pki/private/${var.openvpn_users[0]}.key /etc/openvpn/ || echo "Erro ao copiar ${var.openvpn_users[0]}.key"

              # Ajustar permissões para que ec2-user possa ler os arquivos
              echo "Ajustando permissões..."
              chmod 644 /etc/openvpn/ca.crt
              chmod 644 /etc/openvpn/${var.openvpn_users[0]}.crt
              chmod 644 /etc/openvpn/${var.openvpn_users[0]}.key

              # Criar arquivo de configuração do servidor
              echo "Criando arquivo de configuração do servidor..."
              cat <<EOT > /etc/openvpn/server.conf
              port 1194
              proto udp
              dev tun
              ca ca.crt
              cert server.crt
              key server.key
              dh dh.pem
              server 10.8.0.0 255.255.255.0
              push "redirect-gateway def1"
              push "dhcp-option DNS 8.8.8.8"
              keepalive 10 120
              cipher AES-256-CBC
              persist-key
              persist-tun
              status openvpn-status.log
              verb 3
              EOT

              # Criar o arquivo de serviço OpenVPN
              echo "Criando arquivo de serviço OpenVPN..."
              cat <<EOT > /usr/lib/systemd/system/openvpn@server.service
              [Unit]
              Description=OpenVPN server instance
              After=network.target

              [Service]
              Type=forking
              ExecStart=/usr/sbin/openvpn --daemon --config /etc/openvpn/server.conf
              ExecReload=/bin/kill -HUP \$MAINPID
              WorkingDirectory=/etc/openvpn
              Restart=always

              [Install]
              WantedBy=multi-user.target
              EOT

              # Recarregar systemd e habilitar o serviço
              echo "Habilitando e iniciando OpenVPN..."
              systemctl daemon-reload
              systemctl enable openvpn@server || echo "Erro ao habilitar o serviço"
              systemctl start openvpn@server || echo "Erro ao iniciar o serviço"

              # Configurar encaminhamento de IP
              echo "Configurando encaminhamento de IP..."
              echo 1 > /proc/sys/net/ipv4/ip_forward
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p

              # Configurar regras de firewall
              echo "Configurando iptables..."
              dnf install -y iptables-services
              iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
              service iptables save

              echo "Configuração do OpenVPN concluída!"
              EOF

  tags = {
    Name = "OpenVPN-Server"
  }
}

resource "aws_security_group" "openvpn_sg" {
  vpc_id = var.vpc_id
  name   = "openvpn-sg"

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH para gerenciamento"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Saida para todos os destinos"
  }

  tags = {
    Name = "OpenVPNSecurityGroup"
  }
}