# Módulo: compute
# Un servidor EC2 que ejecuta la tienda dentro de un contenedor Docker.
# Se administra con Session Manager (SSM), sin abrir el puerto 22 (SSH).

# Última imagen de Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Rol que permite a la instancia conectarse a Session Manager
resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.web_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  ebs_optimized               = true

  root_block_device {
    encrypted   = true # disco cifrado en reposo
    volume_type = "gp3"
  }

  # Si cambia el código de la app, Terraform recrea el servidor con la nueva versión
  user_data_replace_on_change = true
  user_data_base64 = base64gzip(templatefile("${path.module}/user_data.sh.tftpl", {
    app_py       = filebase64("${path.root}/../app/app.py")
    dockerfile   = filebase64("${path.root}/../app/Dockerfile")
    requirements = filebase64("${path.root}/../app/requirements.txt")
    db_host      = var.db_host
    db_name      = var.db_name
    db_user      = var.db_username
    db_password  = var.db_password
    cache_host   = var.cache_host
  }))

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  tags = {
    Name = "${var.name_prefix}-web"
  }
}
