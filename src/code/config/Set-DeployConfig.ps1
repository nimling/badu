function Set-DeployConfig {
    [CmdletBinding()]
    param (
        [DeployConfig]$DeployConfig,
        [Switch]$Force
    )
    

    #if the instance id is not the same as the current instance, throw. except if its a developer
    if($DeployConfig.dev.ignoreInstance -eq $false -and $DeployConfig.dev.enabled)
    {
        $CurrentInstance = (get-pscallstack)[-1].GetHashCode()
        if($global:deployConfig.InstanceId -ne $CurrentInstance -and !$Force){
            throw "Failed to set the deployConfig. please make sure you have it instanced within the same callstack. If you are a developer, add dev.ignoreinstance = true to your deployconfig.json"
        }
    }

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Used for global config singleton')]
    $global:deployConfig = $DeployConfig
}