function New-DeployConfig {
    [CmdletBinding()]
    param (
        [DirectoryInfo]$WorkingPath,
        [string]$ActiveEnvironment
    )
    
    begin { 
        $FileName = 'badu'
        Set-BaduLogContext -Tag "BaduConfig"
        #region load the config file contents
        $BaduConfigFile = Get-ChildItem $WorkingPath.FullName -File -filter "$filename.json?" | Select-Object -first 1
        if (!$BaduConfigFile) {
            Write-BaduError "could not find a $FileName.json/jsonc in '$WorkingPath'"
            throw "could not find a $FileName.json/jsonc in '$WorkingPath'"
        }

        Write-BaduVerb "Loading deployConfig from '$BaduConfigFile'"
        $BaduConfigContent = Get-Content $BaduConfigFile

        #clean up jsonc file (remove comments)
        if ($BaduConfigFile.Extension -eq '.jsonc') {
            Write-BaduDebug "Fixing jsonc file before parsing"
            $BaduConfigContent = $BaduConfigContent | Where-Object { $_ -notmatch '^\s*//' }
        }
        $deployConfigObject = $BaduConfigContent | ConvertFrom-Json  #-Depth 90
        #endregion
    }
    
    process {
        # Write-BaduVerb $deployConfigObject.gettype()
        try{
            $Config = [deployconfig]::new($deployConfigObject,$ActiveEnvironment)
            $config.workingPath = $BaduConfigFile.Directory.FullName
        }
        catch{
            Write-BaduError "Failed to initialise $FileName config : $_"
            throw $_
        }

        Set-DeployConfig -DeployConfig $Config -force
    }
    
    end {
        
    }
}