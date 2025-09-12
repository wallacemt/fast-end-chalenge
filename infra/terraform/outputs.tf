output "swarm_public_ips" {
  value       = aws_instance.swarm.*.public_ip
  description = "Public IPs of the swarm instances"
}