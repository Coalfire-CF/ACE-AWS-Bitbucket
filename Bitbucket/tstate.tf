terraform {
  required_version = "~>1.2.0"
  backend "s3" {
    bucket         = "launchpad-us-gov-west-1-tf-state"
    region         = "us-gov-west-1"
    key            = "launchpad-us-gov-west-1-bitbucket-state.tfstate"
    dynamodb_table = "launchpad-us-gov-west-1-state-lock"
    encrypt        = true
    profile        = "launchpad-mgmt"
  }
}
