terraform {  
    required_providers {  
        harness = {  
            source = "harness/harness"  
            version = ">=0.37.5"  
 #           version = "0.24.2"  
        }  
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>3.0"
        }
    }  
}
