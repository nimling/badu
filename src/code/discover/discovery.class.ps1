enum deploymentScope{
    Tenant
    ManagementGroup
    Subscription
    ResourceGroup
}

enum deploymentType{
    Arm
    Bicep
}

class deploymentScopeInfo{
    [string]$Name
    [string]$Id
    [deploymentScope]$Scope
    [string[]]$Parents #array of parent scope ids
}

class deploymentItem{
    [deploymentScope]$scope
    [string]$ScopeName
    [string]$name
    [string]$fullName
    # [string]$parametersFullName
    [string]$environment
    [string]$type
    [hashtable]$parameters
    [int]$priority

    [string]getScopeShortName()
    {
        $return = ""
        switch($this.scope){
            'Tenant' {
                $return = "Ten"
            }
            "ManagementGroup" {
                $return = "Mg"
            }
            "Subscription" {
                $return = "Sub"
            }
            "ResourceGroup" {
                $return = "Rg"
            }
        }
        return $return
    }

    [string]ListString(){
        $ScopeShort = $this.getScopeShortName()
        $PriorityWithPad = "{0:d8}" -f $this.priority
        $Pad = "-"*(([int]$this.scope))
        return "|$Pad($($this.environment):$($ScopeShort):$($this.ScopeName))->$($this.name) ($PriorityWithPad)"
    }
    [string]ToString(){
        $ScopeShort = $this.getScopeShortName()

        $PriorityWithPad = "{0:d8}" -f $this.priority
        return "($ScopeShort)$($this.ScopeName):$($this.name) ($PriorityWithPad)"
    }
}
<#
    scope = subscription
    id = subscription id
    name = subscription name
    filePath = path to the deployment file
    parameterFilePath = path to the parameter file
    basename = name of the deployment file
    environment = environment name
    type = deployment type (arm, bicep)
#>



