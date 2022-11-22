resource "aws_security_group_rule" "my-rule" {
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    description = "my rule"
}

resource "aws_security_group_rule" "public-access" {
    type = "egress"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_alb_listener" "my-alb-listener" {
    port     = "80"
    protocol = "HTTP"
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

 resource "aws_apigatewayv2_stage" "bad_example2" {
   deployment_id = aws_api_gateway_deployment.example.id
   rest_api_id   = aws_api_gateway_rest_api.example.id
   stage_name    = "example"
 }


 resource "aws_apigatewayv2_stage" "bad_example3" {
   deployment_id = aws_api_gateway_deployment.example.id
   rest_api_id   = aws_api_gateway_rest_api.example.id
   stage_name    = "example3"
 }

 resource "aws_security_group_rule" "public-access2" {
    type = "egress"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_alb_listener" "elb-listener" {
    port     = "80"
    protocol = "HTTP"
}
