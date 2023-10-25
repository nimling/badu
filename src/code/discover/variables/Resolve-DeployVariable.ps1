function Resolve-DeployVariable {
    [CmdletBinding()]
    param (
        [string]$Type,
        [hashtable]$ConfigValues
    )
    
    begin {
        
    }
    
    process {
        switch($Type){
            "static" {
                Resolve-DeployVariableStatic @ConfigValues
            }
            "processvariable" {
                Resolve-DeployVariableProcess @ConfigValues
            }
            "keyvault"{
                Resolve-DeployVariableKeyVault @ConfigValues
            }
            "identity"{
                Resolve-DeployVariableIdentity @ConfigValues
            }
            default {
                throw "Invalid variable type: $Type"
            }
        }
    }
    
    end {
        
    }
}