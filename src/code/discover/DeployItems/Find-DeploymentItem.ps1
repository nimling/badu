using namespace System.IO
<#
.SYNOPSIS
Finds deploymentScripts 

.NOTES
General notes
#>
function Find-DeploymentItem {
    [CmdletBinding()]
    [OutputType([deploymentItem])]
    param (
        [string]$Path,
        [string]$Environment,
        [String]$ParentScope,
        [string]$ParentName,
        [int]$Priority = 00000000
    )
    begin {
        Set-BaduLogContext -Tag 'Find Items'
        $DeployConfig = Get-DeployConfig
        $RelativePath = $DeployConfig.getRelativePath($Path)
        $ScopedEnvironmentName = ($DeployConfig.environments | Where-Object { $_.isScoped }).name
        $sep = [System.IO.Path]::DirectorySeparatorChar
    }
    process {
        #getting scope: tenant, managementGroup, subscription, resourceGroup
        $CurrentScope = Get-DeployScope -path $path
        if($ParentScope)
        {
            if($ParentScope -ne 'ManagmentGroup' -and $CurrentScope -eq 'ManagementGroup'){
                #ignores management group if parent is not management group
            }
            elseif(([int][deploymentScope]$ParentScope) -gt ([int][deploymentScope]$CurrentScope)){
                    throw "cannot put a $CurrentScope deployment inside a $ParentScope deplotyment"
            }
        }

        if($RelativePath -eq '.'){
            # $Scope = "subscription"
            Write-BaduVerb "Discovering deployment items in '$path', scope: $scope"
        }
        else{
            Write-BaduVerb "Discovering deployment items in '$RelativePath', scope: $scope"
        }

        #Getting environment, if not set by parameter
        if([string]::IsNullOrEmpty($Environment))
        {
            $Environment = Get-deployEnvironment -item (get-item $path)
            if($Environment)
            {
                Write-BaduVerb "Found environment: $Environment"
            }
        }

        #Getting files, and 
        # Write-BaduVerb "Getting files and folders"
        $Files = Get-ChildItem -Path $path -File|Where-Object{$_.Extension -eq ".bicep" -or $_.Extension -eq ".json" }
        $Files = $Files|Select-ByEnvironment
        $Folders = Get-ChildItem -Path $path -Directory|Select-ByEnvironment

        $items = @()
        $items += $files
        $items += $folders
        $sortMap = $items|Group-DeployItem

        #process each bucket of dict
        foreach($item in $sortMap.getEnumerator()){
            #figure out the priority. each scope adds 2 trailing zeros
            switch($CurrentScope)
            {
                'Tenant' {
                    $priority = $priority + 1000000
                }
                "ManagementGroup" {
                    $priority = $priority + 10000
                }
                "Subscription" {
                    $priority = $priority + 100
                }
                "ResourceGroup" {
                    $priority = $priority + 1
                }
            }

            foreach($FileSystemItem in $Item.Value)
            {
                $Relpath = $DeployConfig.getRelativePath($FileSystemItem.FullName)
                if($FileSystemItem -is [DirectoryInfo]){
                    # $ThisRelativePath = Join-Path -Path $RelativePath -ChildPath $FileSystemItem.Name
                    Write-BaduVerb "Processing folder $Relpath"
                    $param = @{
                        Path = $FileSystemItem.FullName
                        Environment = $Environment
                        ParentScope = $CurrentScope
                        Priority = $priority
                        ParentName = (split-path $Path -Leaf)|remove-EnvNotation
                    }
                    Find-DeploymentItem @param #$FileSystemItem.fullname #-Level ($Level + 1)
                }
                else {
                    # $ThisRelativePath = Join-Path -Path $RelativePath -ChildPath $FileSystemItem.Name
                    $ParameterFile = Get-ChildItem -Path $path -File -Filter "$($FileSystemItem.basename).parameters.json"
                    $DeployParam = @{}
                    if(!$ParameterFile)
                    {
                        Write-BaduWarning "No parameter file found for $RelativePath$sep$($FileSystemItem.name), one should always be present"
                    }
                    else{
                        Write-BaduVerb $ParameterFile.FullName
                        $DeployParam = ConvertTo-ParamObject -ParamFile $ParameterFile
                    }
                    $ScopeName = $FileSystemItem.directory.name|Remove-EnvNotation
                    Write-output ([deploymentItem]@{
                        name = $FileSystemItem.basename
                        FullName = $FileSystemItem.FullName
                        scope = $CurrentScope
                        ScopeName = $CurrentScope -eq 'resourcegroup'? "$parentName/$($ScopeName)" : $ScopeName
                        parameters = $DeployParam
                        # parametersFullName = $ParameterFile.FullName
                        environment = $environment
                        Priority = $priority
                        Type = $FileSystemItem.Extension.TrimStart('.')
                    })
                }
            }
            # if($item.val)
        }


        # $folders|Select-ByEnvironment|%{
        #     Find-DeploymentItem -path $_ #-RelativePath (join-path $RelativePath $_.name) -Root $Root -Level ($Level + 1)
        # }
    }
    end {
    }
}
