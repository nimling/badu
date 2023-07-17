#region using
#endregion
#region remove_on_build
using namespace System.Collections.generic
using namespace System.IO
#endregion

[cmdletbinding(SupportsShouldProcess)]
param(
    [parameter(
        HelpMessage = "Only needed if you make a diff on the different environment"
    )]
    [string]$env,
    [parameter(
        HelpMessage = "Only start files with this name. supports wildcards"
    )]
    [string]$name,

    [String]$Path = $psscriptroot,

    [parameter(
        HelpMessage = "
        this will set badu in a special state meant to get a quick overview of what will happen.
        list: will list all deployments that will be made
        dryrun: this is a mix of whatif and list, it will list what deployents it should have made and what parameters to use
        unusedVar: will list all variables that are not used in any bicep file"
    )]
    [ValidateSet(
        "list",
        "dryRun",
        "variableUse",
        "default"
    )]
    [string[]]$action = "default"
)


#region BuildID

#endregion

#region remove_on_build
$Global:BuildId = "DEV"
Get-ChildItem "$PSScriptRoot/code/*.ps1" -Recurse -Exclude "*.tests.ps1"| ForEach-Object {
    Write-Verbose "importing $($_.basename) \$([System.IO.Path]::GetRelativePath("$PSScriptRoot/src/code",$_.FullName))"
    . $_.FullName
}
#endregion

#region class

#endregion

#region functions

#endregion funtions

#Main
$StartingConsoleTitle = $Host.UI.RawUI.WindowTitle
$StartingConsoleTitle = [console]::Title
try{
    Write-BaduHeader
    # return "hey"
    Set-BaduLogContext -tag "main" -Clear
    $PSCmdlet.MyInvocation.BoundParameters.GetEnumerator()|ForEach-Object{
        # Set-BaduLogContext -tag "main" -Clear
        # Set-BaduLogContext -tag "main" -IsSubFunction
        Write-BaduVerb "param: $($_.key) = $($_.value)"
    }
    Write-BaduVerb "Build: $BuildId"
    if($Path){
        $Path = [System.IO.Path]::GetFullPath($path)
    }
    
    # $global:_Output = @{}
    
    if ($WhatIfPreference) {
        Write-BaduWarning "THIS IS WHATIF BUILD. NO CHANGES WILL HAPPEN"
    }
    
    # $InformationPreference = "continue"
    
    #validating that the subfolder have bicep files in them
    Write-BaduVerb "root path: $Path"
    
    New-DeployConfig -WorkingPath $path -ActiveEnvironment $env
    $DeployConfig = Get-DeployConfig
    # $EnvInfo = $DeployConfig.environments|%{"Enviroment Name: '$($_.name)', IsScoped: $($_.IsScoped)"}
    $rootFolders = gci $Path -Directory|Select-ByEnvironment
    Write-BaduInfo "Discovery: Getting items to deploy"

    Foreach($RootFolder in $rootFolders){
        $DeployItems = Find-DeploymentItem -RelativePath (join-path ".\" $RootFolder.Name) -Root $Path
    }
    # $Scope = gci $PsScriptroot -Filter "*.scope" -file|select -first 1|select -ExpandProperty basename
    # if(!$Scope)
    # {
    #     $Scope = "Subscription"
    # }
    # if($scope)
    
    # Set-DeployScope -Scope "subscription"
    
    <#
    $AvailableSubscriptions = Get-AzSubscription -TenantId $DeployConfig.getTenantId() -WarningAction SilentlyContinue
    # Write-BaduVerb "tenant: $($DeployConfig.getTenantId()), subscriptions: $(($AvailableSubscriptions.Name|%{"'$_'"}) -join ", ")"
    
    Write-BaduVerb "active environments: $($DeployConfig.environments.name -join ", ")"
    
    $SubFolders = Get-ChildItem $PSScriptRoot -Directory | Select-ByEnvironment -Environments $DeployConfig.Environments -All
    $subFolders = $subFolders | Update-DeploySorting
    $UsingSubFolders = $subFolders | Where-Object { ($_.name | Remove-EnvNotation -Env $DeployConfig.environments.name) -in $AvailableSubscriptions.Name }
    
    $SubFolders | Where-Object { $_.name -notin $UsingSubFolders.name } | ForEach-Object {
        Write-BaduWarning "Skipping subscrpition folder $($_.name) (subscription '$(($_.name|Remove-EnvNotation -Env $DeployConfig.environments.name))') because it is not found within your tenant"
    }
    
    $commonparameters = @{
        Erroraction = "stop"
    }
    # Write-BaduVerb "subfilders: $($SubFolders.name -join ", ")"
    Write-Information "processing $($SubFolders.count) subscriptions"
    if ($WhatIfPreference -and $SubFolders.count) {
        Write-BaduVerb "whatif: processing $($SubFolders.count) subscription folders: $($SubFolders.name -join ", ")"
    }
    
    :subFolderSearch foreach ($subFolder in $UsingSubFolders) {
        Write-BaduVerb "**Processing subscription folder '$($subFolder.name)'**"
        $subscriptionName = $subFolder.name | Remove-EnvNotation -Env $DeployConfig.Environments.name
        $subscriptionId = ($AvailableSubscriptions | Where-Object { $_.Name -eq $SubscriptionName }).id
    
        #has name changed? meaning the subscription folder has an env notation
        #this means that i can ignore any search for env notation inside the folder
        $SubscriptionHasEnvNotation = $subFolder.name -ne $SubscriptionName
    
        if ((get-azcontext).Subscription.id -ne $subscriptionId) {
            Write-Information "updating context to subscription '$subscriptionName'"
    
            $contextParam = @{
                SubscriptionName = $subscriptionName
                ErrorAction      = "Stop"
                WhatIf           = $false
                Debug            = $false
                Verbose          = $false
                WarningAction    = "SilentlyContinue"
            }
            Set-AzContext @contextParam | Out-Null
        }
    
        #get bicep files in subscription folder
        # $SubBicepFiles = Get-ChildItem $subFolder.FullName -Filter "*.bicep" -File | Update-DeploySorting
        $SubBicepFiles = Get-DeploymentFile $subFolder.FullName | Update-DeploySorting
        $SubBicepFiles = $SubBicepFiles | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$subscriptionHasEnvNotation
        Write-BaduVerb "Found $($SubBicepFiles.count) bicep files in subscription folder '$($subFolder.name)'"
        #Deploy bicep files within subscription scope
        if ($name) {
            $FilteredFiles = $SubBicepFiles | Where-Object { $_.basename -like $name }
            #report what files where filtered away
            $SubBicepFiles | Where-Object { $_.Name -notin $FilteredFiles.Name } | ForEach-Object {
                Write-BaduVerb "Skipping file $($_.FullName) because it does not match the filter '$name'"
            }
            $subBicepFiles = $FilteredFiles
        }
        $SubBicepFiles | Invoke-BicepDeployment -Context 'Subscription' @commonparameters -action $action
    
        #get folders and sort them if sort file exists. having multiple commands give better error handling, instead of one long pipe
        $RgFolders = Get-ChildItem $subFolder.FullName -Directory
        $RgFolders = $RgFolders | Where-Object { Get-ChildItem $_.fullname -filter "*.bicep" -file } 
        if (@($RgFolders).count -eq 0 ) {
            break :subFolderSearch
        }
        $RgFolders = $RgFolders | Update-DeploySorting
        $RgFolders = $RgFolders | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$subscriptionHasEnvNotation
    
        # "-----------------"
        # $RgFolders
        # #only process resource groups that have bicep files
        foreach ($Folder in $RgFolders) {
            Write-BaduVerb "Processing resource group folder '$($Folder.name)'"
            $resourceGroupName = $Folder.name | Remove-EnvNotation -Env $DeployConfig.Environments.name
            $resourceGroupHasEnvNotation = $Folder.name -ne $resourceGroupName
    
            #Validate that rg exists
            $Rg = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $Rg -and $WhatIfPreference -eq $false) {
                throw "Could not find Resource group '$ResourceGroupName'"
            }
            
            $RgBicepFiles = Get-DeploymentFile $Folder.FullName
            # $RgBicepFiles = Get-ChildItem $Folder.FullName -Filter "*.bicep" -File
            $RgBicepFiles = $RgBicepFiles | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$($resourceGroupHasEnvNotation -or $subscriptionHasEnvNotation)
            $RgBicepFiles = $RgBicepFiles | Update-DeploySorting
            if ($name) {
                $FilteredFiles = $RgBicepFiles | Where-Object { $_.basename -like $name }
                $RgBicepFiles | Where-Object { $_.Name -notin $FilteredFiles.Name } | ForEach-Object {
                    Write-BaduVerb "Skipping file $($_.Name) because it does not match the name filter '$name'"
                }
                $RgBicepFiles = $FilteredFiles
            }
    
            $RgBicepFiles | Invoke-BicepDeployment -Context ResourceGroup @commonparameters -action $action
        }
        if($action -eq 'unusedVar'){
            Get-VariableUsage
        }
    }
    #>
}
catch{

}
finally{
    [console]::Title = $StartingConsoleTitle
}