terraform {
  cloud {
    organization = "Satish_Terraform"

    workspaces {
      name = "Terraform_Final"
    }
  }
}

provider "aws" {
  region = var.region
}