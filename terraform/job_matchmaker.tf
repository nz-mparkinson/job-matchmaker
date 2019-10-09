provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_instance" "apache1" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  tags = {
    Name = "apache1"
  }
}

resource "aws_instance" "apache2" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  tags = {
    Name = "apache2"
  }
}

resource "aws_instance" "apache3" {
  ami           = "ami-02eac2c0129f6376b"
  instance_type = "t2.micro"
  tags = {
    Name = "apache3"
  }
}

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
  skip_final_snapshot  = "true"
}





