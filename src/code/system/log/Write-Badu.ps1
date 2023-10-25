function Write-Badu {
    [CmdletBinding()]
    param (
        [ValidateSet(
            'Info',
            'Warning',
            'Error',
            'Verbose',
            'Debug',
            "System"
        )]
        $Level = 'Info',

        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message,

        [string]$OnceTag,

        [System.Management.Automation.CallStackFrame[]]$Callstack
    )
    begin {
        #Use OnceTag to only write once. sucks to have a warning popping up 100 times
        if(![string]::IsNullOrEmpty($OnceTag)){
            $Config = Get-DeployConfig
            $Written = [bool]$Config.messageTags[$OnceTag]
            if($Written){
                return
            }
            $Config.messageTags[$OnceTag] = $true
            Set-DeployConfig -Config $Config
        }

        #get log context. send in callstack with itself removed
        $ctx = @{
            Tag           = 'TEMP'
            IsSubFunction = $false
            Tab           = 0
        }

        if (!$Callstack) {
            $Callstack = (Get-PSCallStack | Select-Object -Skip 1)
        }
        $Ctx = Get-BaduLogContext -CallStack $Callstack
    }
    process {
        $msg = $Message -join " "
        $tag = $ctx.Tag
        $levelMap = @{
            'Info'    = 'Inf'
            'Warning' = 'Wrn'
            'Error'   = 'Err'
            'Verbose' = 'Vrb'
            'Debug'   = 'Dbg'
        }
        $prefix = "<$($levelMap[$Level])>$("    " * $ctx.tab)<$tag>"
        $out = "$prefix $msg"

        switch ($Level) {
            'Info' {
                Write-Host $out -ForegroundColor Gray
            }
            'Warning' {
                if ($WarningPreference -eq 'SilentlyContinue') { return }
                Write-Host $out -ForegroundColor DarkYellow
            }
            'Error' {
                Write-Host $out -ForegroundColor Red
                # Write-host ($Message|fl * -force|out-string)
                if($Message.ScriptStackTrace)
                {
                    Write-host "$prefix  $("-" * 5) Callstack $("-" * 5)" -ForegroundColor Red
                    $Message.ScriptStackTrace.split("`n")|%{
                        Write-Host $prefix $_ -ForegroundColor Red
                    }
                }
                else{
                    Write-host "$prefix  $("-" * 5) Callstack $("-" * 5)" -ForegroundColor Red
                    $Callstack|%{
                        Write-Host $prefix $_ -ForegroundColor Red
                    }
                }
            }
            'Verbose' {
                if ($VerbosePreference -eq 'SilentlyContinue') { return }
                Write-Host $out -ForegroundColor Cyan
            }
            'Debug' {
                if($DebugPreference -eq 'SilentlyContinue') { return }
                Write-Host $out -ForegroundColor Magenta
            }
        }
    }
    end {}
}

function Write-BaduVerb {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message
    )
    Write-Badu -Level Verbose -Message $Message -Callstack (Get-PSCallStack | Select-Object -Skip 1)
}

function Write-BaduDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message
    )
    Write-Badu -Level Debug -Message $Message -Callstack (Get-PSCallStack | Select-Object -Skip 1)
}

function Write-BaduInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message
    )
    Write-Badu -Level Info -Message $Message -Callstack (Get-PSCallStack | Select-Object -Skip 1)
}

function Write-BaduWarning {
    [CmdletBinding()]
    param (
        [string]$OnceTag,
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message
    )
    $param = @{
        Level     = 'Warning'
        Message   = $Message
        Callstack = (Get-PSCallStack | Select-Object -Skip 1)
    }
    if ($OnceTag) {
        $param.OnceTag = $OnceTag
    }
    Write-Badu @param
}

function Write-BaduError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        $Message
    )
    Write-Badu -Level Error -Message $Message -Callstack (Get-PSCallStack | Select-Object -Skip 1)
}