function Set-WindowTitle {
    [CmdletBinding()]
    param (
        [parameter(ParameterSetName = 'Save')]
        [string]$Title,
        [parameter(ParameterSetName = 'Save')]
        [Switch]$SaveOriginalTitle,
        [parameter(ParameterSetName = 'Load')]
        [Switch]$LoadOriginalTitle
    )
    
    begin {
    }
    
    process {
        if($global:Badu_Dotsourced -eq $true){
            return
        }
        switch($PSCmdlet.ParameterSetName){
            'Save' {
                if($SaveOriginalTitle)
                {
                    $Global:Badu_WindowTitle = $host.ui.RawUI.WindowTitle
                }
            }
            'Load' {
                $Title = $Global:Badu_WindowTitle
                if([string]::IsNullOrEmpty($Title)){
                    $Title = $host.ui.RawUI.WindowTitle
                }
            }
        }

        $host.ui.RawUI.WindowTitle = $Title
    }
    
    end {
        
    }
}