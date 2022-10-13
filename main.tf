resource "aws_security_group_rule" "my-rule" {
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    description = "my rule"
}

#This is just a comment
resource "aws_alb_listener" "my-alb-listener" {
    port     = "443"
    protocol = "HTTPS"
}

resource "aws_db_security_group" "my-group" {
}

resource "azurerm_managed_disk" "source" {
    encryption_settings {
        enabled = false
    }
}