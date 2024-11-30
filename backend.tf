terraform {
  backend "s3" {
    bucket         = "petpoha-frontend-terraform-state-bucket"
    key            = "terraform/state.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks"
  }
}
