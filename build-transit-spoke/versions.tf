terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "2.21.1-6.6.ga"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.16.0"
    }
  }
}