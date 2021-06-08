# ################################
# # ENI
# ################################
resource "aws_network_interface" "web" {
  count       = local.vm_count
  subnet_id   = aws_subnet.public[count.index % 2].id
  private_ips = [trimsuffix(cidrsubnet(aws_subnet.public[count.index % 2].cidr_block, 8, floor(11 + count.index / 2)), "/32")]
  # private_ips     = [element(split("/", cidrsubnet(aws_subnet.public[count.index % 2].cidr_block, 8, 11 + count.index)), 0)]
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = format("${var.prefix}-web-%02d", count.index + 1)
  }
}

################################
# EC2
################################
data "aws_ssm_parameter" "amzn2_latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web" {
  count                   = local.vm_count
  ami                     = data.aws_ssm_parameter.amzn2_latest_ami.value
  instance_type           = "t2.micro"
  iam_instance_profile    = aws_iam_instance_profile.ec2.name
  disable_api_termination = false
  monitoring              = false
  user_data               = file("./param/userdata.sh")
  key_name                = "${var.prefix}-key"

  network_interface {
    network_interface_id = aws_network_interface.web[count.index].id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = false
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 10
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name = format("${var.prefix}-web-%02d", count.index + 1)
  }

  volume_tags = {
    Name = format("${var.prefix}-web-%02d", count.index + 1)
  }
}

output "web_public_ip" {
  description = "valThe public IP address assigned to the instanceue"
  value = {
    for instance in aws_instance.web :
    instance.id => instance.public_ip
  }
}
