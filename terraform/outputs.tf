output "airflow_url" {
  value = aws_mwaa_environment.this.webserver_url 
}