provider "aws" {
  access_key = "AKIAJDJ222VKN5OF2QJA"
  secret_key = "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"
  region     = "us-east-1"
}

# create the VPC
resource "aws_vpc" "vpc-RoK" {
  cidr_block           = "10.0.0.0/26"
  instance_tenancy     = "${var.instanceTenancy}" 
  enable_dns_support   = "${var.dnsSupport}" 
  enable_dns_hostnames = "${var.dnsHostNames}"
  tags {
    Name = "VPC RoK"
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "gtw-RoK" {
  vpc_id = "${aws_vpc.vpc-RoK.id}"
  tags {
      Name = "RoK Internet Gateway"
  }
}

# create public Subnet 1
resource "aws_subnet" "subnet-public-a-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-east-1a"
  tags = {
     Name = "Public Subnet RoK"
  }
}

# create private Subnet 1
resource "aws_subnet" "subnet-private-a-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.16/28"
  availability_zone       = "us-east-1a"
  tags = {
     Name = "Private Subnet RoK"
  }
}

# create public Subnet 2
resource "aws_subnet" "subnet-public-b-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.32/28"
  availability_zone       = "us-east-1b"
  tags = {
     Name = "Public Subnet RoK 2"
  }
}

# create private Subnet 2
resource "aws_subnet" "subnet-private-b-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.48/28"
  availability_zone       = "us-east-1b"
  tags = {
     Name = "Private Subnet RoK 2"
  }
}

# create private route table (no access to gateway)
resource "aws_route_table" "private-rt-RoK" {
  vpc_id = "${aws_vpc.vpc-RoK.id}"

  tags = {
    Name = "Private Route Table"
  }
}

#create public route table
resource "aws_route_table" "public-rt-RoK" {
  vpc_id = "${aws_vpc.vpc-RoK.id}"

  tags = {
    Name = "Public Route Table"
  }
}

# Create the Internet Access
resource "aws_route" "RoK-internet-access" {
  route_table_id        = "${aws_route_table.public-rt-RoK.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gtw-RoK.id}"
}

# Associate the public Route Table with the public Subnet A
resource "aws_route_table_association" "pub-subnet-a-routing-RoK" {
    subnet_id      = "${aws_subnet.subnet-public-a-RoK.id}"
    route_table_id = "${aws_route_table.public-rt-RoK.id}"
}

# Associate the public Route Table with the public Subnet B
resource "aws_route_table_association" "pub-subnet-b-routing-RoK" {
    subnet_id      = "${aws_subnet.subnet-public-b-RoK.id}"
    route_table_id = "${aws_route_table.public-rt-RoK.id}"
}

# Associate the private Route Table with the private Subnet A
resource "aws_route_table_association" "priv-subnet-a-routing-RoK" {
    subnet_id      = "${aws_subnet.subnet-private-a-RoK.id}"
    route_table_id = "${aws_route_table.private-rt-RoK.id}"
}

# Associate the private Route Table with the private Subnet B
resource "aws_route_table_association" "priv-subnet-b-routing-RoK" {
    subnet_id      = "${aws_subnet.subnet-private-b-RoK.id}"
    route_table_id = "${aws_route_table.private-rt-RoK.id}"
}

# Create NACL for VPC
resource "aws_network_acl" "nacl-RoK" {
    vpc_id = "${aws_vpc.vpc-RoK.id}"
    tags = {
      Name = "RoK Network ACL"
    }
    subnet_ids = ["${aws_subnet.subnet-public-a-RoK.id}","${aws_subnet.subnet-public-b-RoK.id}","${aws_subnet.subnet-private-a-RoK.id}","${aws_subnet.subnet-private-b-RoK.id}"]
}

# Create NACL outbound rule for smtp access
resource "aws_network_acl_rule" "nacl-rule-out-smtp-RoK" {
    network_acl_id = "${aws_network_acl.nacl-RoK.id}"
    egress         = true
    rule_number    = 200
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 25
    to_port        = 25
}

# Create NACL inbound rule for http access
resource "aws_network_acl_rule" "nacl-rule-in-http-RoK" {
    network_acl_id = "${aws_network_acl.nacl-RoK.id}"
    egress         = false
    rule_number    = 50
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 80
    to_port        = 80
}

# Create NACL inbound rule for ssh access
resource "aws_network_acl_rule" "nacl-rule-in-ssh-RoK" {
    network_acl_id = "${aws_network_acl.nacl-RoK.id}"
    egress         = false
    rule_number    = 100
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 22
    to_port        = 22
}

# Create main applicatin servers security group
resource "aws_security_group" "main-sg-RoK" {
  name        = "http_inbound_only"
  description = "Allow all http inbound traffic"
  vpc_id      = "${aws_vpc.vpc-RoK.id}"
}

# Create main security group http inbound rule
resource "aws_security_group_rule" "sg-rule-http-in-RoK" {
  security_group_id = "${aws_security_group.main-sg-RoK.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Create main security group ssh inbound rule
resource "aws_security_group_rule" "sg-rule-ssh-in-RoK" {
  security_group_id = "${aws_security_group.main-sg-RoK.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Get an AMI id
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ami-ubuntu-18.04*"]
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

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
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

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_s3_bucket.s3-main-bucket-RoK.arn}/sandbox"
    },
    {
      "Action": [
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.file-processing-queue-RoK.arn}"
    }
  ]
}
EOF
}

# Create application instance 1
resource "aws_instance" "app-instance-1-RoK" {
  ami               = "${data.aws_ami.ubuntu.id}"
  instance_type     = "t2.micro"
  subnet_id         = "${aws_subnet.subnet-public-a-RoK.id}"
  vpc_security_group_ids   = ["${aws_security_group.main-sg-RoK.id}"]
  availability_zone = "us-east-1a"
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
  instance_type     = "t2.micro"
  subnet_id         = "${aws_subnet.subnet-public-b-RoK.id}"
  vpc_security_group_ids   = ["${aws_security_group.main-sg-RoK.id}"]
  availability_zone = "us-east-1b"
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

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_s3_bucket.s3-infra-bucket-RoK.arn}/elb-logs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
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
#   availability_zone = "us-east-1b"
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

