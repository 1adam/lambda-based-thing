terraform {
  backend "s3" {
    bucket = ""
    key = ""
    region = ""
    encrypt = true
    acl = "private"
    kms_key_id = ""
    dynamodb_table = ""
   }
}