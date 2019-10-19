#Define the AWS region 
variable "region" {
  type    = "string"
  default = "us-east-1"
}

#Define what AMI to use for AWS EC2 instances depending on the region
variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-02eac2c0129f6376b"          #CentOS7 - us-east-1
    "us-west-2" = "ami-0f2b4fc905b0bd1f1"          #CentOS7 - us-east-2
  }
}
