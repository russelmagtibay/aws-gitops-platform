terraform {
  backend "s3" {
    bucket       = "aws-gitops-platform-tfstate-570515227299"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}