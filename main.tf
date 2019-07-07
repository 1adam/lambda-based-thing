provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# todo... break things out into modules, someday! today? nope.
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
  body = <<END_API
openapi: 3.0.2
info:
  title: "xg-api-app"
  version: 1.0.1
components:
  schemas:
    successfulComm:
      type: object
      properties:
        cid:
          type: string
          format: uuid
        uid:
          type: string
          format: uuid
    err:
      type: object
      properties:
        errCode:
          type: integer
          format: int32
        errMsg:
          type: string
  parameters:
    cid:
      - name: cid
        in: path

paths:
  /hellothere/{uname}:
    parameters:
      - name: uname
        in: path
        required: true
        description: "userName"
        schema:
          type: string
    post:
      summary: conn to xg
      description: Connect to xg
      responses:
        '200':
          description: Successful conn
          content:
            '*/*':
              type: object
              schema:
                $ref: "#/components/schemas/cid"
  /conn/{cid}:
    parameters:
      - name: cid
        in: path
        required: true
        description: "connID"
        schema:
          type: string
    post:
      summary: Comm w xg
      description: Communicate with xg using existing connID
      responses:
        '200':
          description: Successful comm
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/successfulComm"
        default:
          description: "error happen"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/err"



END_API

}