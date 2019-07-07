provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "template_file" "ws_cf_tpl" {
  template = file("${path.module}/cf_tpl/websocket.yaml.tpl")
  vars = {
    s3_bucket = "${aws_s3_bucket.ws_func_deploy.id}"
    conn_key = "${aws_s3_bucket_object.conn_obj.id}"
    msg_key = "${aws_s3_bucket_object.msg_obj.id}"
    disconn_key = "${aws_s3_bucket_object.disconn_obj.id}"
  }
}

# todo... break things out into modules, someday! today? nope.
resource "aws_dynamodb_table" "conns" {
  name = "xg-conns-${terraform.workspace}"
  write_capacity = 5
  read_capacity = 5
  hash_key = "ConnID"
  range_key = "UserID"

  attribute {
    name = "ConnID"
    type = "S"
  }

  attribute {
    name = "UserID"
    type = "S"
  }

  stream_enabled = true
  stream_view_type = "KEYS_ONLY"

  ttl {
    attribute_name = "ObjTTL"
    enabled = true
  }

  tags = {
    Name = "user-conns-ddbt"
    Project = "xg"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_dynamodb_table" "users" {
  name = "xg-users-${terraform.workspace}"
  write_capacity = 5
  read_capacity = 5
  hash_key = "UserID"
  range_key = "Username"

  attribute {
    name = "UserID"
    type = "S"
  }

  attribute {
    name = "Username"
    type = "S"
  }

  tags = {
    Name = "users-ddbt"
    Project = "xg"
    Environment = "${terraform.workspace}"
 }
}

resource "aws_api_gateway_rest_api" "main" {
  name = "xg-${terraform.workspace}-api"
  description = "xg api"
  body = file("${path.module}/openapi.yaml")
  endpoint_configuration {
    types = [
      "REGIONAL"
    ]
  }
}

resource "aws_s3_bucket" "ws_func_deploy" {
  bucket_prefix = "xg-${terraform.workspace}-ws-func-"
  acl = "private"
  tags = {
    Project = "xg"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket_object" "conn_obj" {
  bucket = aws_s3_bucket.ws_func_deploy.id
  key = "deploy/conn-obj/latest.zip"
  source = "${var.conn_obj_zipfile}"
  etag = filemd5("${var.conn_obj_zipfile}")
}

resource "aws_s3_bucket_object" "msg_obj" {
  bucket = aws_s3_bucket.ws_func_deploy.id
  key = "deploy/msg-obj/latest.zip"
  source = "${var.msg_obj_zipfile}"
  etag = filemd5("${var.msg_obj_zipfile}")
}

resource "aws_s3_bucket_object" "disconn_obj" {
  bucket = aws_s3_bucket.ws_func_deploy.id
  key = "deploy/disconn-obj/latest.zip"
  source = "${var.disconn_obj_zipfile}"
  etag = filemd5("${var.disconn_obj_zipfile}")
}

resource "aws_cloudformation_stack" "ws_api" {
  name = "xg-${terraform.workspace}-ws"

  parameters = {
    TableName = "xg_ws_conns"
  }

  template_body = data.template_body.ws_cf_tpl.rendered
  capabilities = ["CAPABILITY_IAM","CAPABILITY_AUTO_EXPAND"]
  tags = {
    Project = "xg"
    Environment = "${terraform.workspace}"
  }
}