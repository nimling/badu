function ConvertTo-ParamObject {
    param(
        [System.IO.FileInfo]$ParamFile
    )
    begin {
        Set-BaduLogContext -Tag "Convert Param File" -IsSubFunction
        $return = @{}
        $deployConfig = Get-DeployConfig
        $RelativePath = $deployConfig.getRelativePath($ParamFile.FullName)
        Write-Baduverb "Converting param file '$RelativePath' to param object"
        # $deployConfig = Get-DeployConfig
    }
    process {
        $ParamContent = Get-Content $ParamFile -raw

        #Remove comment lines form json
        $ParamContent = $ParamContent -replace '(?m)^\s*\/\/.*$', ''

        $ParamItem = $ParamContent| ConvertFrom-Json -AsHashtable

        #Schema Validation
        $ParamSchema = $ParamItem.'$schema'
        if($null -eq $ParamSchema) {
            Write-BaduInfo "No '`$schema' found in json file '$RelativePath'. you sure this is a real params file?"
        }
        if($deployConfig.SchemaStore[$ParamSchema] -and $deployConfig.SchemaStore.keys -like 'https://schema.management.azure.com*deploymentParameters.json*') {
           Write-BaduWarning "You are using different schema versions for your param files, that might cause slowdowns, and unexpected behavior." -OnceTag 'Warn_SchemaVersionMismatch'
        }

        # $test = Test-BaduJson -Path $paramfile
        $test = $true
        if(!$test)
        {
            Write-BaduError "Failed to parse json file '$RelativePath'"
            return $return
        }

        $params = $paramItem.parameters
        if($null -eq $params) {
            $ParamKey = $ParamItem.keys|?{$_ -eq "parameters"}
            $params = $ParamItem[$ParamKey]
            if($null -eq $params) {
                Write-BaduWarning "No parameters found in '$RelativePath'"
                return $return
            }
            $deployConfig = Get-DeployConfig
            Write-BaduWarning "ParameterFile '$RelativePath' has wrong casing on key 'parameter': '$ParamKey'."
        }

        foreach ($parameter in $params.GetEnumerator()) {
            $ParamName = $parameter.Name
            $ParamValue = $parameter.Value
            if ($parameter.Value.value -is [string]) {
                $ParamValue = $parameter.Value.value
                #find replacement if value is a variable reference
                Write-BaduVerb "Handling parameter '$ParamName'"
                $ParamValue = Build-DeployVariable -val $ParamValue
                # $References = Get-VariableReferenceInString -String $ParamValue | select -Unique
                # if($References.count -gt 0) {
                #     Write-BaduVerb "Found $($References.count) variable references in '$ParamName'"
                #     $ParamValue = Build-DeployVariable -VarRefs $References -val $ParamValue
                # }
            }
            elseif(![string]::IsNullOrEmpty($parameter.Value.value))
            {
                $ParamValue = $parameter.Value.value
            }
            else{
                $ParamValue = $parameter.Value
            }
            $return.Add($ParamName, $ParamValue)
        }
    }
    end {
        return $return
    }
}