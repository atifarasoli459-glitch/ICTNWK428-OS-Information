# ICTNWK428 - Operating System Information Module
# Student: Atifa
# Purpose: Public and private functions used by os_information_Atifa.ps1.

$script:SystemSnapshot = $null

function Get-SystemSnapshot {
    <#
    .SYNOPSIS
    Collects the computer information used by the OS information script.

    .DESCRIPTION
    Retrieves the operating system, computer system, WinRM service and TrustedHosts
    information once and stores the results in a module-level cache. Reusing this
    snapshot prevents the same CIM commands from being called repeatedly.

    .OUTPUTS
    PSCustomObject containing OperatingSystem, RemoteServiceStatus,
    ManufacturerModel, ComputerName, DomainName, TrustedHosts and Architecture.

    .NOTES
    Parameters: None.
    This is a private helper function and is not exported from the module.
    #>
    try {
        if ($null -eq $script:SystemSnapshot) {
            $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            $winRmService = Get-Service -Name WinRM -ErrorAction Stop
            $trustedHostsValue = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop).Value

            if ([string]::IsNullOrWhiteSpace($trustedHostsValue)) {
                $trustedHostsValue = 'No trusted hosts configured'
            }

            $script:SystemSnapshot = [PSCustomObject]@{
                OperatingSystem     = $operatingSystem.Caption
                RemoteServiceStatus = $winRmService.Status.ToString()
                ManufacturerModel   = (
                    "Manufacturer: $($computerSystem.Manufacturer); Model: $($computerSystem.Model)"
                )
                ComputerName        = $computerSystem.Name
                DomainName          = $computerSystem.Domain
                TrustedHosts        = $trustedHostsValue
                Architecture        = $operatingSystem.OSArchitecture
            }
        }

        return $script:SystemSnapshot
    }
    catch {
        return "Error: Unable to collect computer information. $($_.Exception.Message)"
    }
}

function Get-ClientComputerInformation {
    <#
    .SYNOPSIS
    Returns one selected item of computer information.

    .DESCRIPTION
    Accepts a property name from the menu and returns only that requested item from
    the cached system snapshot. This keeps one function responsible for retrieving
    one requested property at a time.

    .PARAMETER PropertyName
    Specifies the computer information to return. Valid values are OperatingSystem,
    RemoteServiceStatus, ManufacturerModel, ComputerName, DomainName, TrustedHosts
    and Architecture.

    .OUTPUTS
    String containing the requested computer information, or an error message.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'OperatingSystem',
            'RemoteServiceStatus',
            'ManufacturerModel',
            'ComputerName',
            'DomainName',
            'TrustedHosts',
            'Architecture'
        )]
        [string]$PropertyName
    )

    try {
        $snapshot = Get-SystemSnapshot

        if ($snapshot -is [string] -and $snapshot -like 'Error:*') {
            return $snapshot
        }

        return $snapshot.$PropertyName
    }
    catch {
        return "Error: Unable to retrieve $PropertyName. $($_.Exception.Message)"
    }
}

function Get-AllClientsComputerInformation {
    <#
    .SYNOPSIS
    Returns all required computer information in one list.

    .DESCRIPTION
    Retrieves the cached system snapshot once and returns all seven required items
    as an ordered list for menu option 8.

    .OUTPUTS
    String containing all required computer information in list format, or an error message.

    .NOTES
    Parameters: None.
    #>
    try {
        $snapshot = Get-SystemSnapshot

        if ($snapshot -is [string] -and $snapshot -like 'Error:*') {
            return $snapshot
        }

        $allInformation = [ordered]@{
            'Operating System'               = $snapshot.OperatingSystem
            'Windows Remote Service (WinRM)' = $snapshot.RemoteServiceStatus
            'Manufacturer and Model'         = $snapshot.ManufacturerModel
            'Computer Name'                  = $snapshot.ComputerName
            'Domain Name'                    = $snapshot.DomainName
            'Trusted Hosts'                  = $snapshot.TrustedHosts
            'OS Architecture'                = $snapshot.Architecture
        }

        return ($allInformation | Format-List | Out-String)
    }
    catch {
        return "Error: Unable to retrieve all computer information. $($_.Exception.Message)"
    }
}

function Show-OSInfoMenu {
    <#
    .SYNOPSIS
    Displays the nine menu options for the user.

    .DESCRIPTION
    Writes the OS information menu to the screen. The function only displays the
    menu and does not read input or retrieve computer information.

    .OUTPUTS
    Menu text displayed in the PowerShell console.

    .NOTES
    Parameters: None.
    #>
    try {
        Write-Output ''
        Write-Output '===== ITWorks Operating System Information ====='
        Write-Output '1. Operating System'
        Write-Output '2. Windows Remote Service Status (WinRM)'
        Write-Output '3. Computer Manufacturer and Model'
        Write-Output '4. Computer Name'
        Write-Output '5. Computer Domain Name'
        Write-Output '6. Trusted Hosts'
        Write-Output '7. Operating System Architecture'
        Write-Output '8. Get All Information'
        Write-Output '9. Quit'
    }
    catch {
        Write-Output "Error: Unable to display the menu. $($_.Exception.Message)"
    }
}

function Start-OSInfoProgram {
    <#
    .SYNOPSIS
    Runs the main OS information menu program.

    .DESCRIPTION
    Repeatedly displays the menu, reads the user's selection and calls the appropriate
    public information function. The loop continues until the user selects option 9.
    Invalid entries, including letters or numbers outside 1 to 9, produce a clear
    validation message and the menu is displayed again.

    .OUTPUTS
    Displays the selected computer information, validation messages and exit message.

    .NOTES
    Parameters: None.
    #>
    try {
        $choice = ''

        while ($choice -ne '9') {
            Show-OSInfoMenu
            $choice = Read-Host 'Enter a menu option (1-9)'

            switch ($choice) {
                '1' { Write-Output (Get-ClientComputerInformation -PropertyName 'OperatingSystem') }
                '2' { Write-Output (Get-ClientComputerInformation -PropertyName 'RemoteServiceStatus') }
                '3' { Write-Output (Get-ClientComputerInformation -PropertyName 'ManufacturerModel') }
                '4' { Write-Output (Get-ClientComputerInformation -PropertyName 'ComputerName') }
                '5' { Write-Output (Get-ClientComputerInformation -PropertyName 'DomainName') }
                '6' { Write-Output (Get-ClientComputerInformation -PropertyName 'TrustedHosts') }
                '7' { Write-Output (Get-ClientComputerInformation -PropertyName 'Architecture') }
                '8' { Write-Output (Get-AllClientsComputerInformation) }
                '9' { Write-Output 'Exiting program.' }
                default { Write-Output 'Invalid selection. Please enter a number from 1 to 9.' }
            }
        }
    }
    catch {
        Write-Output "Error: The program encountered an unexpected problem. $($_.Exception.Message)"
    }
}

# Only these functions are public and available after Import-Module.
Export-ModuleMember -Function @(
    'Get-ClientComputerInformation',
    'Get-AllClientsComputerInformation',
    'Show-OSInfoMenu',
    'Start-OSInfoProgram'
)
