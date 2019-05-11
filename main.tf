provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "terraform"
  region                  = "us-east-1"
}

# Get an AMI id
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ubuntuAmiNamePatten}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  owners = ["234212695392"] # Canonical ami-0ac019f4fcb7cb7e6
}

# Create key pair to allow accessing instances
resource "aws_key_pair" "renato-ec2-keypair" {
    key_name = "renato-ec2-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXyBYeS2BYc1fSJAt9feulak1XSYY3aM/L23qGsTAqtnFuFd+TbGTxlM1py1RwqveTb3sbKLk9iW42T99DGBK2C6Y1gjUNJyoNRczZhuMlyW1JPKnWXKz9oYjF/s4mQSKlOe/XO5AlbGQpItNsvbANiBpf4O+NyzR4Urr2f2EeXzbsYHhNMopOIaD52YtLa9TblSA/CZ8qFtT3f+I/iSvLxBnhE8BdK+gOlrD0YUsK5W6EfehXz3t7AY/Qcr429DIAJRi+o/jnzuGVhv5JfbE+odomLTc7GG5/oMwKW+KMbfFFUgumqFAqIsWsCNDP1KP1Qkq8c76vY4IMAVAUNyUj renatorp@c3p0"
}

# Create app instance role
resource "aws_iam_role" "app-instance-role-RoK" {
  name = "app-instance-role-RoK"
  assume_role_policy = "${file("assume-role-policies/ec2.json")}"
}

# Create iam instance profile to associate role to instances
resource "aws_iam_instance_profile" "app-instance-profile-RoK" {
  name = "app-instance-profile-RoK"
  role = "${aws_iam_role.app-instance-role-RoK.name}"
}

# Create access policies for app instances 
resource "aws_iam_role_policy" "app-instance-policy-RoK" {
  name = "app-instance-policy-RoK"
  role = "${aws_iam_role.app-instance-role-RoK.id}"
  policy = "${file("policies/ec2-appInstance.json")}"
}

# Create application instance 1
resource "aws_instance" "app-instance-1-RoK" {
  ami               = "${data.aws_ami.ubuntu.id}"
  instance_type     = "${var.instanceType}"
  subnet_id         = "${aws_subnet.subnet-public-a-RoK.id}"
  vpc_security_group_ids   = ["${aws_security_group.main-sg-RoK.id}"]
  availability_zone = "${var.availabilityZoneA}"
  key_name = "${aws_key_pair.renato-ec2-keypair.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.app-instance-profile-RoK.name}"
  associate_public_ip_address = false
  tags = {
    Name = "ApplicationInstance-1"
  }
  depends_on = [
    "aws_iam_role_policy.app-instance-policy-RoK"
  ]
}

# Create application instance 2
resource "aws_instance" "app-instance-2-RoK" {
  ami               = "${data.aws_ami.ubuntu.id}"
  instance_type     = "${var.instanceType}"
  subnet_id         = "${aws_subnet.subnet-public-b-RoK.id}"
  vpc_security_group_ids   = ["${aws_security_group.main-sg-RoK.id}"]
  availability_zone = "${var.availabilityZoneB}"
  key_name = "${aws_key_pair.renato-ec2-keypair.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.app-instance-profile-RoK.name}"
  associate_public_ip_address = false
  tags = {
    Name = "ApplicationInstance-2"
  }
  depends_on = [
    "aws_iam_role_policy.app-instance-policy-RoK"
  ]
}

# Reference main app S3 bucket
data "aws_s3_bucket" "s3-main-bucket-RoK" {
  bucket = "ripple-of-knowledge"
}

# Reference infra S3 bucket
data "aws_s3_bucket" "s3-infra-bucket-RoK" {
  bucket = "ripple-of-knowledge-infra"
}


# Create file processing dead letter queue
resource "aws_sqs_queue" "file-processing-queue-dlq-RoK" {
  name                      = "file-processing-queue-dlq-RoK"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# Create file processing message queue
resource "aws_sqs_queue" "file-processing-queue-RoK" {
  name                      = "file-processing-queue-RoK"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.file-processing-queue-dlq-RoK.arn}\",\"maxReceiveCount\":4}"
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "s3-infra-bucket-policy-RoK" {
  bucket = "${data.aws_s3_bucket.s3-infra-bucket-RoK.id}"
  policy = "${file("policies/s3-infraBucket.json")}"
}

# Create load balancer
resource "aws_elb" "elb-RoK" {
  name              = "elb-RoK"
  security_groups   = ["${aws_security_group.main-sg-RoK.id}"]
 
  access_logs {
    bucket        = "${data.aws_s3_bucket.s3-infra-bucket-RoK.bucket}"
    bucket_prefix = "elb-logs"
    interval      = 60
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  instances             = ["${aws_instance.app-instance-1-RoK.id}","${aws_instance.app-instance-2-RoK.id}"]
  subnets               = ["${aws_subnet.subnet-public-a-RoK.id}","${aws_subnet.subnet-public-b-RoK.id}"]
}

## PRÓXIMOS PASSOS
# Verificar se elb foi criado conforme esperado
# Criar banco relacional
# Criar instãncia de processo com respectiva role com permissão de leitura/escrita no s3]
# Organizar arquivos terraform
# Criar aplicação spring boot para receber requisição multipart e enviar arquivo para s3 e enviar msg pra fila
# Criar imagem docker e enviar para ECR
# Acessar instancia via ssh, instalar docker e rodar a aplicação
# Definir próximos passos...

# # Create relational database
# resource "aws_db_instance" "db-instance-RoK" {
#   allocated_storage    = 20
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7.16"
#   instance_class       = "db.t2.micro"
#   name                 = "db-instance"
#   username             = "admin"
#   password             = "admin12345"
#   db_subnet_group_name = "${aws_subnet.subnet-private-a-RoK.id}"
# }

# # Create private application instance
# resource "aws_instance" "app-instance-3-private-RoK" {
#   ami               = "${data.aws_ami.ubuntu.id}"
#   instance_type     = "t2.micro"
#   subnet_id         = "${aws_subnet.subnet-private-b-RoK.id}"
#   availability_zone = "${var.availabilityZoneB}"
#   tags = {
#     Name = "ApplicationInstance-3"
#   }
# }


#####################################################################

# # Create lambda function
# resource "aws_lambda_function" "notification-function-RoK" {
#   function_name = "notification-function"

#   #s3_bucket = "bucket_name"
#   #s3_key    = "file.zip"
#   handler   = "package.Class"
#   runtime   = "java8"

#   role = "${aws_iam_role.iam-lambda-notificatoin-RoK.arn}"
# }

# # Create IAM Role stating that lambda function can access s3 bucket
# resource "aws_iam_role" "iam-lambda-notificatoin-RoK" {
#   name = "lambda-notification"
#   assume_role_policy = "${file("assume-role-policy.json")}"
#} 

