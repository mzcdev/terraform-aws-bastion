# bastion

terraform {
  backend "s3" {
    region = "ap-northeast-2"
    bucket = "terraform-mz-seoul"
    key    = "bastion.tfstate"
  }
  required_version = ">= 0.12"
}

provider "aws" {
  region = "ap-northeast-2"
}

data "template_file" "setup" {
  template = file("../../template/setup.sh")
}

module "bastion" {
  source = "github.com/nalbam/terraform-aws-asg/modules/asg"

  region = "ap-northeast-2"
  city   = "seoul"
  stage  = "dev"
  name   = "demo"
  suffix = "bastion"

  vpc_id = "vpc-025ad1e9d1cb3c27d"

  subnet_ids = [
    "subnet-007a2bd91c7939e85",
    "subnet-0477597c240b95aa8",
    "subnet-0c91c5cd95b319b76",
  ]

  launch_configuration_enable = false
  launch_template_enable      = true
  launch_each_subnet          = false

  associate_public_ip_address = true

  instance_type = "t2.micro"

  user_data = data.template_file.setup.rendered

  volume_size = "8"

  min = "1"
  max = "1"

  on_demand_base = "0"
  on_demand_rate = "0"

  key_name = "nalbam-seoul"
}

// AdministratorAccess
resource "aws_iam_role_policy_attachment" "this" {
  role = module.bastion.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_security_group_rule" "worker-ingress-ssh" {
  description       = "Allow workstation to communicate with the cluster API Server"
  security_group_id = module.bastion.security_group_id
  cidr_blocks       = [
    "221.148.35.250/32", # echo "$(curl -sL icanhazip.com)/32"
  ]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "ingress"
}
