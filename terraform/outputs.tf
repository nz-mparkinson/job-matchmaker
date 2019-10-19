#Output the region
output "region" {
  value = var.region
}

#Output the AMI used
output "ami" {
  value = var.amis[var.region]
}

#Output the RDS instance
output "rds_instance" {
  value = "${aws_db_instance.postgresql1.address}"
}

