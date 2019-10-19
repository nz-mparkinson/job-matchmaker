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

#Output the RDS instance
output "rds_instance" {
  value = "${aws_db_instance.postgresql1.address}"
  description = "The DNS name of the RDS instance"
}

