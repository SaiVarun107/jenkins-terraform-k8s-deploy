output "ec2_ip" {
  value = aws_instance.devops.public_ip
}