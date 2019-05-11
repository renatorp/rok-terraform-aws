
# create the VPC
resource "aws_vpc" "vpc-RoK" {
  cidr_block           = "${var.vpcCIDRblock}"
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
  availability_zone       = "${var.availabilityZoneA}"
  tags = {
     Name = "Public Subnet RoK"
  }
}

# create private Subnet 1
resource "aws_subnet" "subnet-private-a-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.16/28"
  availability_zone       = "${var.availabilityZoneA}"
  tags = {
     Name = "Private Subnet RoK"
  }
}

# create public Subnet 2
resource "aws_subnet" "subnet-public-b-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.32/28"
  availability_zone       = "${var.availabilityZoneB}"
  tags = {
     Name = "Public Subnet RoK 2"
  }
}

# create private Subnet 2
resource "aws_subnet" "subnet-private-b-RoK" {
  vpc_id                  = "${aws_vpc.vpc-RoK.id}"
  cidr_block              = "10.0.0.48/28"
  availability_zone       = "${var.availabilityZoneB}"
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
  destination_cidr_block = "${var.defaultCIDRblock}"
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
    cidr_block     = "${var.defaultCIDRblock}"
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
    cidr_block     = "${var.defaultCIDRblock}"
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
    cidr_block     = "${var.defaultCIDRblock}"
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
  cidr_blocks       = ["${var.defaultCIDRblock}"]
}

# Create main security group ssh inbound rule
resource "aws_security_group_rule" "sg-rule-ssh-in-RoK" {
  security_group_id = "${aws_security_group.main-sg-RoK.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.defaultCIDRblock}"]
}