#Define the AWS provider
provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}



#Define a Security Group
resource "aws_security_group" "terraform_security_group" {
  name        = "terraform_security_group"
  description = "Terraform Security Group"

  tags = {
    Name = "terraform_security_group"
  }
}

#Define Security Group egress rules
resource "aws_security_group_rule" "egress_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow all inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

#Define Security Group ingress rules
resource "aws_security_group_rule" "ingress_allow_all_internal" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  source_security_group_id = "${aws_security_group.terraform_security_group.id}"
  description     = "Allow All inbound internal"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

resource "aws_security_group_rule" "ingress_allow_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow HTTP inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

resource "aws_security_group_rule" "ingress_allow_ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow SSH inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}



#Define what image to use for EC2 instances
variable "image_id" {
  type = string
  default = "ami-02eac2c0129f6376b"          #CentOS7 - us-east-1
#  default = "ami-0f2b4fc905b0bd1f1"          #CentOS7 - us-east-2
}

#Define a EC2 Instances
resource "aws_instance" "apache1" {
  ami           = var.image_id
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "web_servers"
  }
  root_block_device {
    delete_on_termination = "true"
  }

  security_groups = ["${aws_security_group.terraform_security_group.name}"]
}

resource "aws_instance" "apache2" {
  ami           = var.image_id
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "web_servers"
  }
  root_block_device {
    delete_on_termination = "true"
  }

  security_groups = ["${aws_security_group.terraform_security_group.name}"]
}

resource "aws_instance" "apache3" {
  ami           = var.image_id
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "web_servers"
  }
  root_block_device {
    delete_on_termination = "true"
  }

  security_groups = ["${aws_security_group.terraform_security_group.name}"]
}



#Get the details of the AWS service account
data "aws_elb_service_account" "main" {}

#Define a S3 Bucket
resource "aws_s3_bucket" "storage1" {
  bucket = "job-matchmaker-storage1"
  acl    = "private"
  force_destroy           = "true"

  tags = {
    Name        = "job-matchmaker-storage1"
    Environment = "Dev"
  }

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
      "Resource": "arn:aws:s3:::job-matchmaker-storage1/*",
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

#Define a EC2 Load Balancer
resource "aws_elb" "loadbalancer1" {
  name               = "loadbalancer1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  access_logs {
    bucket        = "job-matchmaker-storage1"
    bucket_prefix = "loadbalancer1"
    interval      = 60
  }

  listener {
#    instance_port     = 8000
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#  listener {
#    instance_port      = 8000
#    instance_protocol  = "http"
#    lb_port            = 443
#    lb_protocol        = "https"
#    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/search.html"
    interval            = 30
  }

  instances                   = ["${aws_instance.apache1.id}", "${aws_instance.apache2.id}", "${aws_instance.apache3.id}"]
#  instances                   = ["${aws_instance.apache1.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "loadbalancer1"
  }

  security_groups = ["${aws_security_group.terraform_security_group.id}"]
}



#Define a RDS Instance, creating the job_matchmaker database
resource "aws_db_instance" "postgresql1" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.5"
  instance_class       = "db.t2.micro"
  name                 = "job_matchmaker"
#  username             = "postgres"
#  password             = "postgres"
  username             = "job_matchmaker"
  password             = "job_matchmaker"
  parameter_group_name = "default.postgres11"
  identifier           = "postgresql1"
#  publicly_accessible  = "true"
  publicly_accessible  = "false"
  backup_retention_period = 3
  skip_final_snapshot  = "true"

  vpc_security_group_ids = ["${aws_security_group.terraform_security_group.id}"]
}



/*
#Configure the PostgreSQL provider
provider "postgresql" {
  host = "${aws_db_instance.postgresql1.address}"
  username = "postgres"
  password = "postgres"
  connect_timeout = 15
  sslmode = "require"
  superuser = "false"

#  depends_on  = ["aws_db_instance.postgresql1"]      #TODO reserved for future release of Terraform, uncomment then
}

#Define a PostgreSQL user
resource "postgresql_role" "job_matchmaker" {
  name     = "job_matchmaker"
  login    = true
  password = "job_matchmaker"
  skip_reassign_owned = true		#Required otherwise error on destroy

  depends_on  = ["aws_db_instance.postgresql1"]
}

#Grant a PostgreSQL user privileges on a database
resource postgresql_grant "job_matchmaker" {
  database    = "job_matchmaker"
  role        = "job_matchmaker"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["ALL"]

  depends_on  = ["aws_db_instance.postgresql1", "postgresql_role.job_matchmaker"]
}
*/



