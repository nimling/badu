function Get-DeployScope {
    [CmdletBinding()]
    [OutputType([deploymentScope])]
    param (
        [string]$Path
    )
    
    begin {
        Set-BaduLogContext -Tag 'Get Scope' -IsSubFunction
        if(!(Test-Path $path)){
            throw "Path does not exist: $path"
        }
        $Scopes = [System.Collections.Generic.List[String]]::new()
        $RelativePath = (Get-DeployConfig).getRelativePath($Path)
    }
    
    process {
        # $Scope = ""

        #check if it has a bicep file and check that
        $BicepFiles = Get-ChildItem $path -Filter '*.bicep' -File -ErrorAction SilentlyContinue
        $ARMFiles = Get-ChildItem $path -Filter '*.json' -File -ErrorAction SilentlyContinue|?{$_|Select-String -Pattern "schema.management.azure.com"}
        if($BicepFiles)
        {
            $targetScopes = $BicepFiles|select-string "targetscope.*"
            $targetScopes|Select-Object -First 1|ForEach-Object{
                $Scope = $_.line.split("'")[1]
                $Scopes.Add($Scope)
                Write-BaduVerb "Found targetScope '$Scope' in bicep file '$($_.Filename)'"
            }
            if($Scopes.count -lt 1){
                Write-BaduVerb "Found bicep files without targetScope in $RelativePath. assuming 'resourceGroup'"
                $Scopes.Add("resourceGroup")
            }
        }

        if($ARMFiles)
        {
            $ArmInfo = $ARMFiles|Get-ArmFileInfo

            $ArmInfo.TargetScope|?{$_}|%{
                write-BaduVerb "Found targetScope '$($_)' in arm file '$($_.Filename)'"
                $Scopes.Add($_)
            }
        }

        $Scopes = $Scopes|?{$_}|Select-Object -Unique
        $Scope = $Scopes|Select-Object -First 1
# ) 
#         if(($Scopes.count -eq 0) -and ($BicepFiles -or $ARMFiles)){
#             Write-BaduVerb "No targetScope found, but found Bicep/ARM files in '$($RelativePath)'. assuming 'resourceGroup'"
#             $Scope = "resourceGroup"
#         }
        if($Scopes.count -gt 1){
            Write-BaduError "$($Scopes.count) targetScopes found in '$($RelativePath)': $($Scopes -join ', ')"
            throw "Multiple targetScopes found in '$($RelativePath)': $($Scopes -join ', ')"
        }

        if(!$Scope){
            Write-BaduVerb "no scope or deploy files detected in '$($RelativePath)'. defaulting to 'subscription'"
            $Scope = "subscription"
        }
        return [deploymentScope]$scope
    }
    
    end {
        
    }
}

# Get-DeployScope -Path C:\git\nim\badu\.local\template\deploy\samna-test -Verbose