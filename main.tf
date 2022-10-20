resource "aws_security_group_rule" "my-rule" {
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    description = "my rule"
}

resource "aws_security_group_rule" "public" {
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
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

 resource "aws_apigatewayv2_stage" "bad_example" {
   api_id = aws_apigatewayv2_api.example.id
   name   = "example-stage"
 }

 resource "aws_apigatewayv2_stage" "bad_example" {
   deployment_id = aws_api_gateway_deployment.example.id
   rest_api_id   = aws_api_gateway_rest_api.example.id
   stage_name    = "example"
 }