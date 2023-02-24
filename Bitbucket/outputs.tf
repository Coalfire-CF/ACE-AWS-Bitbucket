output "bitbucket_instance_sg_id" {
  value       = aws_security_group.bitbucket_instance_sg.id
  description = "BitBucket Security Group ID"
}