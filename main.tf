provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "terraform"
  region                  = "us-east-1"
}

# Create application instance 1 + application instance 2
module "app-instance-RoK" {
  source                  = "./modules/ec2"
  vpc_security_group_id   = "${aws_security_group.main-sg-RoK.id}"
  num_instances = 2

  instances               = [
    {
      policy                  = "${file("policies/ec2-appInstance.json")}"
      subnet_id               = "${aws_subnet.subnet-public-a-RoK.id}" 
      availability_zone       = "${var.availabilityZoneA}" 
      instance_name           = "ApplicationInstance-1"
    },
    {
      policy                  = "${file("policies/ec2-appInstance.json")}"
      subnet_id               = "${aws_subnet.subnet-public-b-RoK.id}" 
      availability_zone       = "${var.availabilityZoneB}" 
      instance_name           =  "ApplicationInstance-2"
    }
  ]
}

module "sqs-queue-RoK" {
  source = "./modules/sqs"
  name   = "file-processing-queue-RoK"
}

# Reference infra S3 bucket
data "aws_s3_bucket" "s3-infra-bucket-RoK" {
  bucket = "ripple-of-knowledge-infra"
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

  instances             = ["${module.app-instance-RoK.instance_ids}"]
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

