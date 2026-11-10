# ICTNWK428 - Operating System Information
# Student: Atifa
# Purpose: Import the OS information module and start the menu program.
# Environment: Windows Server 2022 / Windows PowerShell.

try {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'OSInfoFunctions.psm1'

    Import-Module -Name $modulePath -Force -ErrorAction Stop

    Start-OSInfoProgram
}
catch {
    Write-Output "Error: Unable to start the OS information program. $($_.Exception.Message)"
}
