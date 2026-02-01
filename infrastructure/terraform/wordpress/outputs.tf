output "vpc_id" {
  value = aws_vpc.commerce_cloud.id
  description = "The ID of the created VPC"
}
