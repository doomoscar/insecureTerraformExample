resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.test.arn
  port = 80
  default_action {
    type = "redirect"

    redirect {
      port        = "80"
      protocol    = "HTTP"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_s3_bucket" "bad_example" {

    versioning {
        enabled = false
    }
}

resource "aws_security_group" "bad_example" {
    egress {
        cidr_blocks = ["0.0.0.0/0"]
    }
 }

 resource "aws_s3_bucket" "bad_example" {

    versioning {
        enabled = false
    }
}