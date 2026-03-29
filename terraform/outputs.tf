output "website_url" {
  description = "The public URL to access the web application"
  value       = "http://${aws_instance.web.public_ip}"
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}
