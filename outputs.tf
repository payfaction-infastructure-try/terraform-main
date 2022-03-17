output "load_balancer_ip" {
  value = aws_lb.default.dns_name
}

output "vpc_id" {
  value = aws_vpc.default.id
}

output "lb_listener" {
  value = aws_lb_listener.default
}

output "load_balancer_security_group_id" {
  value = aws_security_group.alb_security_group.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

