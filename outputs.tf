output "ws_endpoint" {
  value = aws_cloudformation_stack.ws_api.outputs.WebSocketURI
}