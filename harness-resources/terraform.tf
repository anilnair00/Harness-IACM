terraform {  
    required_providers {  
        harness = {  
            source = "harness/harness"  
            version = "0.24.2"  
        }  
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>3.0"
        }
    }  
    backend "azurerm" {
      use_oidc         = true
      use_azuread_auth = true
  }
}
