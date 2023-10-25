Describe "Get-ArmFileInfo" {
    BeforeDiscovery {
        $TemplateTypes = @(
            'managementGroup',
            'subscription',
            'tenant',
            ''
        )
        $ApiVersions = @(
            '2019-08-01',
            '2020-06-01',
            '2020-09-01'
        )
    
        $testcases = $TemplateTypes | % {
            $type = $_
            $ApiVersions | % {
                @{
                    SchemaType = "$type`DeploymentTemplate"
                    Version    = $_
                    Type       = $type ? $type : "resourceGroup"
                }
            }
        }
    }

    AfterEach {
        Get-ChildItem $TestDrive | Remove-Item -Recurse -Force
    }

    It "should return null if not a json file" {
        $file = New-Item -Path $TestDrive -Name "test.txt" -ItemType File -Value "..."
        $file | Get-ArmFileInfo | Should -Be $null
    }

    it "Should return null if its empty" {
        $file = New-Item -Path $TestDrive -Name "test.json" -ItemType File
        $file | Get-ArmFileInfo | Should -Be $null
    }

    it "Should return null if its not a deployment template" {
        $file = New-Item -Path $TestDrive -Name "test.json" -ItemType File -Value "{}"
        $file | Get-ArmFileInfo | Should -Be $null
    }

    it "should return info if its a deployment template" -TestCases $testcases {
        param(
            [string]$SchemaType,
            [string]$Version,
            [string]$Type
        )
        $obj = @{
            "`$schema" = "https://schema.management.azure.com/schemas/$Version/$SchemaType.json"
        }
        $file = New-Item -Path $TestDrive -Name "test.json" -ItemType File -Value ($obj | ConvertTo-Json)
        # Write-Host ($obj | ConvertTo-Json)
        $ArmInfo = $file | Get-ArmFileInfo
        $ArmInfo | Should -Not -Be $null
        $ArmInfo.TargetScope | Should -Be $Type
        $ArmInfo.Version | Should -Be $Version
    }
}