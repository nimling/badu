using namespace NJsonSchema.Validation
using namespace NJsonSchema

#TODO: make this waaay faster.. or is it fast enough?

function Test-BaduJson {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 0)]
        [System.IO.FileInfo]$Path,
        [parameter(ParameterSetName = 'content', Mandatory = $true, Position = 0)]
        [string]$Content,
        [switch]$IgnoreSchema
    )
    begin {
        #import json content
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $Content = Get-Content -Path $Path -Raw
        }
    }
    process {
        $Object = $Content | ConvertFrom-Json

        if ($IgnoreSchema -or !$Object.'$schema') {
            $Validator = [JsonSchema]::FromJsonAsync('{}').Result
            try {
                $Validator.Validate($Content)
            } catch {
                Write-BaduError "Failed to parse json content: $_"
                return $false
            }
            return $true
        }

        #Check if schema is in store
        $Config = Get-DeployConfig
        $schemaName = $Object.'$schema'
        if (!$config.SchemaStore[$schemaName]) {
            Write-Baduverb = "No cached schema found for '$schemaName'. Downloading schema from '$schemaName'"
            try {
                $WebRequest = Invoke-webrequest -Uri $schemaName -Method Get
            } catch {
                Write-BaduError "Failed to download schema from '$schemaName': $_"
                throw $_
            }
            $ScemaStoreItem = [SchemaStoreItem]::new()
            $ScemaStoreItem.raw = $WebRequest.Content
            Write-BaduVerb "Generating validator for schema. this might take some time.."
            $AsyncTask = [JsonSchema]::FromJsonAsync($ScemaStoreItem.raw)
            $TimeTaken = [System.Diagnostics.Stopwatch]::StartNew()
            while(!$AsyncTask.IsCompleted) {
                Write-BaduVerb "Waiting for schema to be generated ($('{0:N0}' -f $TimeTaken.Elapsed.TotalSeconds) seconds, state: $($AsyncTask.Status)).."
                Start-Sleep -Seconds 3
            }
            $ScemaStoreItem.schema = $AsyncTask.Result
            $config.SchemaStore[$schemaName] = $ScemaStoreItem
            Set-DeployConfig -DeployConfig $config
        }

        #load schema from store
        $ScemaStoreItem = $config.SchemaStore[$schemaName]
        $Validator = $ScemaStoreItem.schema

        #validate
        try {
            $validateArr = $Validator.Validate($Content)
            if(!$validateArr)
            {
                return $false
            }
            else {
                Write-BaduWarning "Found $($validateArr.count) errors within your json file. use verbose to see them"

                #figure out what errors accured
                $validateArr|%{
                    $Val = $_
                    if($Val -is [NJsonSchema.Validation.ChildSchemaValidationError]){
                        $_val = $val.errors.toarray()|?{$_ -isnot [NJsonSchema.Validation.ChildSchemaValidationError]}
                        if($_val.count -eq 0){
                            $val = $val.errors.findall({$true})
                        }
                        else {
                            $val = $_val
                        }
                    }

                    $val|%{
                        Write-BaduVerbose "$($_.Path)(@$($_.LineNumber):$($_.LinePosition)):"
                        $_.tostring().split("`n")|%{
                            Write-BaduVerbose "`t$_"
                        }
                    }
                }
                return $false
            }
        } catch {
            Write-BaduError "Failed to parse json content: $_"
            return $false
        }
    }
    end {}
}