output "db_host" {
  value = aws_db_instance.main.address
}

output "app_endpoint" {
  value = aws_route53_record.app.fqdn
}

