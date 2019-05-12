#standard-ec2.tf

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

# Create app instance role
resource "aws_iam_role" "app-instance-role-RoK" {
  name = "app-instance-role-RoK"
  assume_role_policy = "${file("modules/ec2/assume-role-policies/ec2.json")}"
}

# Create iam instance profile to associate role to instances
resource "aws_iam_instance_profile" "app-instance-profile-RoK" {
  name = "app-instance-profile-RoK"
  role = "${aws_iam_role.app-instance-role-RoK.name}"
}

# Create access policies for app instances 
resource "aws_iam_role_policy" "app-instance-policy-RoK" {
  count   = "${var.num_instances}"
  name    = "app-instance-policy-RoK"
  role    = "${aws_iam_role.app-instance-role-RoK.id}"
  policy  = "${lookup(var.instances[count.index], "policy")}"
}

# Create standard instance
resource "aws_instance" "standard-instance" {
  count             = "${var.num_instances}"
  ami               = "${data.aws_ami.ubuntu.id}"
  instance_type     = "${var.instance_type}"
  subnet_id         = "${lookup(var.instances[count.index], "subnet_id")}"
  vpc_security_group_ids   = ["${var.vpc_security_group_id}"]
  availability_zone = "${lookup(var.instances[count.index], "availability_zone")}"
  key_name = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.app-instance-profile-RoK.name}"
  associate_public_ip_address = false
  tags = {
    Name = "${lookup(var.instances[count.index], "instance_name")}"
  }
  depends_on = [
    "aws_iam_role_policy.app-instance-policy-RoK"
  ]
}

output "instance_ids" {
  value = ["${aws_instance.standard-instance.*.id}"]
}