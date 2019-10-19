#Output the region used
output "region" {
  value = var.region
  description = "The AWS region used"
}

#Output the AMI used
output "ami" {
  value = var.amis[var.region]
  description = "The AMI used"
}

#Output the RDS DNS name
output "rds_instance" {
  value = "${aws_db_instance.postgresql1.address}"
  description = "The DNS name of the RDS instance"
}

#Output the ELB DNS name
output "elb_instance" {
  value = "${aws_elb.loadbalancer1.dns_name}"
  description = "The DNS name of the Elastic Load Balancer"
}

#Output the EC2 instance DNS names
output "ec2_instances" {
  value = "${aws_instance.web_servers.*.public_dns}"
  description = "The DNS names of the EC2 instances"
}

