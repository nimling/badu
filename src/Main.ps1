# #region using
#endregion
#region remove_on_build
using namespace System.Collections.generic
using namespace System.IO
#endregion

[cmdletbinding(SupportsShouldProcess)]
param(
    [parameter(
        HelpMessage = "Environment to deploy. if not set, it will use all non-scoped environments"
    )]
    [string]$env,
    [parameter(
        HelpMessage = "Only start files with this name. supports wildcards"
    )]
    [string]$name,

    [String]$Path = $psscriptroot,

    [parameter(
        HelpMessage = "
        BETA:
        this will set badu in a special state meant to get a quick overview of what will happen.
        list: will list all deployments that will be made
        dryrun: this is a mix of whatif and list, it will list what deployents it should have made and what parameters to use
        variableUse: will list all variables that are not used in any bicep file,
        dotsource: if loaded as a dotsource with this added, it will just load the functions and not run anything. used for paralell deployment methods
        default: nothing"
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
$Global:Badu_Path = $PSCmdlet.MyInvocation.MyCommand.Source
# $global:Badu_Dotsourced = $action -contains "dotsource"
# return 
Get-ChildItem "$PSScriptRoot/code/*.ps1" -Recurse -Exclude "*.tests.ps1" | ForEach-Object {
    if(!$global:Badu_Async){
        Write-Verbose "importing $($_.basename) \$([System.IO.Path]::GetRelativePath("$PSScriptRoot/src/code",$_.FullName))"
    }
    # Write-Verbose "importing $($_.basename) \$([System.IO.Path]::GetRelativePath("$PSScriptRoot/src/code",$_.FullName))"
    . $_.FullName
}
#endregion

#region class

#endregion

#region functions

#endregion funtions

#Main
# try {
#     if(!$global:Badu_Async){
#         Write-BaduHeader
#         Set-BaduLogContext -tag "main" -Clear
#         $PSCmdlet.MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object {
#             # Set-BaduLogContext -tag "main" -Clear
#             # Set-BaduLogContext -tag "main" -IsSubFunction
#             Write-BaduVerb "param: $($_.key) = $($_.value)"
#         }
#         Write-BaduVerb "Build: $BuildId"
#         Set-WindowTitle -Title "Badu - $BuildId - Start" -SaveOriginalTitle
#         # [console]::Title = "Badu - $BuildId"
#     }

#     if ($Path) {
#         $Path = [System.IO.Path]::GetFullPath($path)
#     }
    
#     if ($WhatIfPreference -and !$global:Badu_Async) {
#         Write-BaduWarning "THIS IS WHATIF BUILD. NO CHANGES WILL HAPPEN"
#     }

#     #validating that the subfolder have bicep files in them
#     if($global:Badu_Async){
#         Write-BaduVerb "Async Mode enabled"
#         return
#     }else{
#         Write-BaduVerb "working path: $Path"
#         New-DeployConfig -WorkingPath $path -ActiveEnvironment $env
#     }

#     $DeployConfig = Get-DeployConfig

#     if ($DeployConfig.environments.Count -eq 0) {
#         Write-BaduWarning "No environments is set in deployconfig.json. Please use environments for better control over what is deployed."
#     }

#     if ($Env) {
#         if ($env -notin $DeployConfig.environments.name) {
#             throw "Could not find environment '$env' in deployconfig.json"
#         }
#     }

#     Set-WindowTitle -Title "Badu - $BuildId - Discovery"
#     Write-BaduInfo "Discovery: Getting items to deploy.."
#     # Write-BaduVerb "$($rootFolders.count) items in root: $($Path)"

#     <#
#         deployitems:
#         list of items to deploy.
#             each item has:
#                 fullname
#                 name
#                 parameter path
#                 environment
#                 scope -> rg, sub, mg, tenant
#                 priority -> when to deploy
#                 type -> arm, bicep
#         go throught each priority and deploy.
#         if multiple has the same priority, deploy them in parallel
#     #>
#     #-RelativePath "./" -Root $Path
#     $param = @{
#         Path = $Path
#     }
#     if ($env) {
#         $param.Environment = $env
#     }

#     $DeployItems = Find-DeploymentItem -path $path | Sort-Object priority

#     if ($name) {
#         $DeployItems = $DeployItems | Where-Object { $_.name -like $name }
#     }

#     #region Action: List items
#     if ($Action -eq 'list') {
#         Write-Host "Scoped Environments: $(($DeployConfig.environments|Where-Object{$_.isScoped -eq $true}).name -join ", ")"
#         Write-Host "Non Scoped Environments: $(($DeployConfig.environments|Where-Object{$_.isScoped -eq $false}).name -join ", ")"
#         Write-Host "Deploying $($DeployItems.count) items"
#         $count = 1
#         $DeployItems | Group-Object priority | ForEach-Object {
#             Write-host -ForegroundColor Yellow "$count`: $($_.name)"
#             $_.group | ForEach-Object {
#                 $deployName = "$($_.scope)->$($_.ScopeName)"
#                 Write-Host -ForegroundColor Cyan "    $($_.scope)->$($_.ScopeName): $($_.name)"
#                 if($null -ne $_.parameters)
#                 {
#                     $paramtab = "    $(" "*$deployName.length) "
#                     foreach ($param in $_.parameters.getenumerator()) {
#                         Write-Host -ForegroundColor Blue "$paramtab param: $($param.name) = $($param.value|convertto-json -depth 1 -compress)"
#                     }

#                 }
#             }
#             $count++
#         }
#         return
#     }
#     #endregion Action: List items

#     #region figure Out Variables
#     Set-WindowTitle -Title "Badu - $BuildId - Deploy"
#     invoke-BaduDeployment -Items $DeployItems -Action $Action

#     #endregion

#     <#
#     |--402 samna/
#     |   tst2
#     |   test2
#     #>
#     # for ($i = 0; $i -lt $rootFolders.Count; $i++) {
#     #     $RootFolder = $rootFolders[$i]
#     #     $DeployItems = Find-DeploymentItem -RelativePath $RelativePath -Root $Path -scope Subscription
#     # }
#     # Foreach($RootFolder in $rootFolders){
#     #     $RelativePath = (join-path ".\" $RootFolder.Name)
#     #     $DeployItems = Find-DeploymentItem -RelativePath $RelativePath -Root $Path -Level 2
#     # }
#     # $Scope = gci $PsScriptroot -Filter "*.scope" -file|select -first 1|select -ExpandProperty basename
#     # if(!$Scope)
#     # {
#     #     $Scope = "Subscription"
#     # }
#     # if($scope)
    
#     # Set-DeployScope -Scope "subscription"
    
#     <#
#     $AvailableSubscriptions = Get-AzSubscription -TenantId $DeployConfig.getTenantId() -WarningAction SilentlyContinue
#     # Write-BaduVerb "tenant: $($DeployConfig.getTenantId()), subscriptions: $(($AvailableSubscriptions.Name|%{"'$_'"}) -join ", ")"
    
#     Write-BaduVerb "active environments: $($DeployConfig.environments.name -join ", ")"
    
#     $SubFolders = Get-ChildItem $PSScriptRoot -Directory | Select-ByEnvironment -Environments $DeployConfig.Environments -All
#     $subFolders = $subFolders | Update-DeploySorting
#     $UsingSubFolders = $subFolders | Where-Object { ($_.name | Remove-EnvNotation -Env $DeployConfig.environments.name) -in $AvailableSubscriptions.Name }
    
#     $SubFolders | Where-Object { $_.name -notin $UsingSubFolders.name } | ForEach-Object {
#         Write-BaduWarning "Skipping subscrpition folder $($_.name) (subscription '$(($_.name|Remove-EnvNotation -Env $DeployConfig.environments.name))') because it is not found within your tenant"
#     }
    
#     $commonparameters = @{
#         Erroraction = "stop"
#     }
#     # Write-BaduVerb "subfilders: $($SubFolders.name -join ", ")"
#     Write-Information "processing $($SubFolders.count) subscriptions"
#     if ($WhatIfPreference -and $SubFolders.count) {
#         Write-BaduVerb "whatif: processing $($SubFolders.count) subscription folders: $($SubFolders.name -join ", ")"
#     }
    
#     :subFolderSearch foreach ($subFolder in $UsingSubFolders) {
#         Write-BaduVerb "**Processing subscription folder '$($subFolder.name)'**"
#         $subscriptionName = $subFolder.name | Remove-EnvNotation -Env $DeployConfig.Environments.name
#         $subscriptionId = ($AvailableSubscriptions | Where-Object { $_.Name -eq $SubscriptionName }).id
    
#         #has name changed? meaning the subscription folder has an env notation
#         #this means that i can ignore any search for env notation inside the folder
#         $SubscriptionHasEnvNotation = $subFolder.name -ne $SubscriptionName
    
#         if ((get-azcontext).Subscription.id -ne $subscriptionId) {
#             Write-Information "updating context to subscription '$subscriptionName'"
    
#             $contextParam = @{
#                 SubscriptionName = $subscriptionName
#                 ErrorAction      = "Stop"
#                 WhatIf           = $false
#                 Debug            = $false
#                 Verbose          = $false
#                 WarningAction    = "SilentlyContinue"
#             }
#             Set-AzContext @contextParam | Out-Null
#         }
    
#         #get bicep files in subscription folder
#         # $SubBicepFiles = Get-ChildItem $subFolder.FullName -Filter "*.bicep" -File | Update-DeploySorting
#         $SubBicepFiles = Get-DeploymentFile $subFolder.FullName | Update-DeploySorting
#         $SubBicepFiles = $SubBicepFiles | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$subscriptionHasEnvNotation
#         Write-BaduVerb "Found $($SubBicepFiles.count) bicep files in subscription folder '$($subFolder.name)'"
#         #Deploy bicep files within subscription scope
#         if ($name) {
#             $FilteredFiles = $SubBicepFiles | Where-Object { $_.basename -like $name }
#             #report what files where filtered away
#             $SubBicepFiles | Where-Object { $_.Name -notin $FilteredFiles.Name } | ForEach-Object {
#                 Write-BaduVerb "Skipping file $($_.FullName) because it does not match the filter '$name'"
#             }
#             $subBicepFiles = $FilteredFiles
#         }
#         $SubBicepFiles | Invoke-BicepDeployment -Context 'Subscription' @commonparameters -action $action
    
#         #get folders and sort them if sort file exists. having multiple commands give better error handling, instead of one long pipe
#         $RgFolders = Get-ChildItem $subFolder.FullName -Directory
#         $RgFolders = $RgFolders | Where-Object { Get-ChildItem $_.fullname -filter "*.bicep" -file } 
#         if (@($RgFolders).count -eq 0 ) {
#             break :subFolderSearch
#         }
#         $RgFolders = $RgFolders | Update-DeploySorting
#         $RgFolders = $RgFolders | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$subscriptionHasEnvNotation
    
#         # "-----------------"
#         # $RgFolders
#         # #only process resource groups that have bicep files
#         foreach ($Folder in $RgFolders) {
#             Write-BaduVerb "Processing resource group folder '$($Folder.name)'"
#             $resourceGroupName = $Folder.name | Remove-EnvNotation -Env $DeployConfig.Environments.name
#             $resourceGroupHasEnvNotation = $Folder.name -ne $resourceGroupName
    
#             #Validate that rg exists
#             $Rg = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
#             if (-not $Rg -and $WhatIfPreference -eq $false) {
#                 throw "Could not find Resource group '$ResourceGroupName'"
#             }
            
#             $RgBicepFiles = Get-DeploymentFile $Folder.FullName
#             # $RgBicepFiles = Get-ChildItem $Folder.FullName -Filter "*.bicep" -File
#             $RgBicepFiles = $RgBicepFiles | Select-ByEnvironment -Environments $DeployConfig.Environments -all:$($resourceGroupHasEnvNotation -or $subscriptionHasEnvNotation)
#             $RgBicepFiles = $RgBicepFiles | Update-DeploySorting
#             if ($name) {
#                 $FilteredFiles = $RgBicepFiles | Where-Object { $_.basename -like $name }
#                 $RgBicepFiles | Where-Object { $_.Name -notin $FilteredFiles.Name } | ForEach-Object {
#                     Write-BaduVerb "Skipping file $($_.Name) because it does not match the name filter '$name'"
#                 }
#                 $RgBicepFiles = $FilteredFiles
#             }
    
#             $RgBicepFiles | Invoke-BicepDeployment -Context ResourceGroup @commonparameters -action $action
#         }
#         if($action -eq 'unusedVar'){
#             Get-VariableUsage
#         }
#     }
#     #>
# } catch {
#     Write-BaduError $_
#     throw $_
# } finally {
#     Set-WindowTitle -LoadOriginalTitle
#     # [console]::Title = $StartingConsoleTitle
# }