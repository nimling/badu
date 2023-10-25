function invoke-BaduDeployment {
    [CmdletBinding()]
    param (
        [deploymentItem[]]$Items,

        [ValidateSet(
            "dryRun",
            "default"
        )]
        [string[]]$action = "default"
    )
    
    begin {
        $config = get-deployconfig
        Set-BaduLogContext -Tag 'Deploy'
    }
    
    process {
        $WorkingPath = $config.workingPath
        $InfoHash = @{}
        $AsyncInfo = [System.Collections.Hashtable]::Synchronized($InfoHash)
        Foreach ($ItemGroup in $Items | Group-Object priority) {
            Write-BaduInfo "Deploying priority group: $($ItemGroup.Name) ($($ItemGroup.Group.Count) items)"
            $ItemGroup.Group | foreach-object -Parallel {
                
                $asyncInfo = $using:AsyncInfo
                $global:Badu_Async_Work = @{
                    Log = [System.Collections.Generic.Dictionary[string, bool]]::new()
                }
                $asyncInfo["$($_.ScopeName)/$($_.Name)"] = $global:Badu_Async_Work
                $Global:Badu_Async = $true
                
                #load badu
                $baduPath = $using:Global:Badu_Path
                . $baduPath -Path $using:WorkingPath
                Set-BaduLogContext -Tag 'DeployRunner'
                #Set Config
                $Config = $using:global:deployConfig
                $CurrentInstance = (get-pscallstack)[-1].GetHashCode()
                $Config.InstanceId = $CurrentInstance
                Set-DeployConfig -DeployConfig $Config -Force

                # $DeploytItem = [deploymentItem]$_
                # Write-BaduInfo "Deploying item: $DeploytItem " #$($DeploytItem.path)"
            }
        }
    }
    
    end {
        
    }
}