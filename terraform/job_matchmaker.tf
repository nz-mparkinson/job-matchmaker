provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}



#Define a EC2 Instance
resource "aws_instance" "apache1" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "apache1"
  }
  root_block_device {
    delete_on_termination = "true"
  }
}

#Define a EC2 Instance
resource "aws_instance" "apache2" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "apache2"
  }
  root_block_device {
    delete_on_termination = "true"
  }
}

#Define a EC2 Instance
resource "aws_instance" "apache3" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "apache3"
  }
  root_block_device {
    delete_on_termination = "true"
  }
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
}



#Define a RDS Instance, creating the job_matchmaker database
resource "aws_db_instance" "postgresql1" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.5"
  instance_class       = "db.t2.micro"
  name                 = "job_matchmaker"
  username             = "postgres"
  password             = "postgres"
  parameter_group_name = "default.postgres11"
  identifier           = "postgresql1"
  publicly_accessible  = "true"
  skip_final_snapshot  = "true"
}



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





