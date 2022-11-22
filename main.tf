resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.test.arn
  port = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}