function Get-DeployEnvironment {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [System.IO.FileSystemInfo]$Item
    )
    begin {
        Set-BaduLogContext -Tag 'Get Env' -IsSubFunction
        $Config = Get-DeployConfig
        $Environments = $Config.environments
    }
    process {
        $Separator = [System.IO.Path]::DirectorySeparatorChar
        if($item.FullName -like "*$Separator")
        {
            $item = get-item $item.FullName.Substring(0, $item.FullName.Length - 1)
        }

        if ($Environments.count -eq 0) {
            return
        }

        # Write-baduDebug "working path : $([Path]::GetFullPath($Config.workingPath))"
        # Write-baduDebug "item.FullName: $([Path]::GetFullPath($item.FullName))"
        if ($item.FullName -eq $Config.workingPath) {
            Write-baduDebug "No environment found for $item"
            return 
        }

        if ($item.basename -like "*.ignore") {
            return
        }

        if ($item.basename -like "*.*") {
            return $item.basename.split('.')[1]
        } else {
            if ($item -is [System.IO.DirectoryInfo]) {
                $parent = $item.parent
            } else {
                $parent = $item.parent
            }
            Write-baduDebug "parent: $parent"
            # $parent = $item -is [System.IO.FileInfo] ? $item.D : $item.parent
            $parent|Get-DeployEnvironment 
        }
    }
    end {
    }
}

# Get-DeployEnvironment -item ''