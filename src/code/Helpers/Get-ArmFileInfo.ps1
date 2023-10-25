class ArmInfo {
    [string]$Filename
    [string]$TargetScope
    [string]$Version
}

function Get-ArmFileInfo {
    [CmdletBinding()]
    [OutputType([ArmInfo])]
    param (
        [parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [System.IO.FileInfo]$Item
    )
    begin {
        $Regex = "https:\/\/schema.management.azure.com\/schemas\/(?'version'[0-9]{4}-[0-9]{2}-[0-9]{2})\/(?'type'[^.]*)Template.json"
    }
    process {
        if ($Item.Extension -ne ".json") {
            return
        }

        $Text = Get-Content $Item.FullName -Raw -ErrorAction SilentlyContinue
        if (!$Text) {
            return
        }

        $Object = $Text | ConvertFrom-Json
        $Schema = $Object.'$schema'
        if (!($schema -match $Regex)) {
            return
        }
        $Scope = ""
        switch ($Matches['type']) {
            'subscriptionDeployment' {
                $Scope = 'subscription'
            }
            'managementGroupDeployment' {
                $Scope = 'managementGroup'
            }
            'tenantDeployment' {
                $Scope = 'tenant'
            }
            'Deployment' {
                $Scope = 'resourceGroup'
            }
            default{
                # Write-BaduError "Unknown ARM template type '$($Matches['type'])' in file '$($Item.FullName)'"
                throw "Unknown ARM template type '$($Matches['type'])' in file '$($Item.FullName)'"
            }
        }
        Write-baduDebug "Found targetScope '$Scope' in arm file '$($Item.FullName)'"
        return [ArmInfo]@{
            Filename    = $Item.Name
            TargetScope = $Scope
            Version     = $Matches['version']
        }
    }
    end {
    }
}