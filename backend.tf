terraform {
  backend "s3" {
    bucket = "tf-s-dev-20190706142601220600000001"
    key = "state/current.tfstate"
    region = "us-east-1"
    encrypt = true
    acl = "private"
    kms_key_id = "arn:aws:kms:us-east-1:394737488529:key/c636b409-c6df-4d8a-9f23-c04375a7a41d"
    dynamodb_table = "tf-s-dev-locking"
   }
}
