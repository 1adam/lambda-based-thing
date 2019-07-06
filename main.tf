provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


resource "aws_dynamodb_table" "conns" {
  name = "xg-conns-${terraform.workspace}"
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
  hash_key = "UserID"

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

