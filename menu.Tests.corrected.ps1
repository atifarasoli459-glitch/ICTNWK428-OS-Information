# ICTNWK428 Pester tests for OSInfoFunctions.psm1
# Compatible with Windows PowerShell Pester 3.4.0
$modulePath = Join-Path $PSScriptRoot 'OSInfoFunctions.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

InModuleScope OSInfoFunctions {
    Describe 'Get-ClientComputerInformation' {
        BeforeEach {
            Mock Get-SystemSnapshot {
                [PSCustomObject]@{
                    OperatingSystem = 'Windows Server 2022'
                    RemoteServiceStatus = 'Running'
                    ManufacturerModel = 'VMware test model'
                    ComputerName = 'SERVER1'
                    DomainName = 'example.test'
                    TrustedHosts = 'No trusted hosts configured'
                    Architecture = '64-bit'
                }
            }
        }

        It 'returns the requested operating system' {
            Get-ClientComputerInformation -PropertyName OperatingSystem |
                Should Be 'Windows Server 2022'
        }
        It 'returns the requested WinRM status' {
            Get-ClientComputerInformation -PropertyName RemoteServiceStatus |
                Should Be 'Running'
        }
        It 'returns the requested manufacturer and model' {
            Get-ClientComputerInformation -PropertyName ManufacturerModel |
                Should Be 'VMware test model'
        }
        It 'returns the requested computer name' {
            Get-ClientComputerInformation -PropertyName ComputerName |
                Should Be 'SERVER1'
        }
        It 'returns the requested domain' {
            Get-ClientComputerInformation -PropertyName DomainName |
                Should Be 'example.test'
        }
        It 'returns the requested trusted hosts' {
            Get-ClientComputerInformation -PropertyName TrustedHosts |
                Should Be 'No trusted hosts configured'
        }
        It 'returns the requested architecture' {
            Get-ClientComputerInformation -PropertyName Architecture |
                Should Be '64-bit'
        }
        It 'calls the shared snapshot helper' {
            Get-ClientComputerInformation -PropertyName ComputerName | Out-Null
            Assert-MockCalled Get-SystemSnapshot -Times 1 -Exactly
        }
    }

    Describe 'Get-AllClientsComputerInformation' {
        It 'formats all seven pieces of computer information' {
            Mock Get-SystemSnapshot {
                [PSCustomObject]@{
                    OperatingSystem = 'Windows Server 2022'
                    RemoteServiceStatus = 'Running'
                    ManufacturerModel = 'VMware test model'
                    ComputerName = 'SERVER1'
                    DomainName = 'example.test'
                    TrustedHosts = 'None'
                    Architecture = '64-bit'
                }
            }
            $result = Get-AllClientsComputerInformation
            $result | Should Match 'Windows Server 2022'
            $result | Should Match 'Running'
            $result | Should Match 'VMware test model'
            $result | Should Match 'SERVER1'
            $result | Should Match 'example.test'
            $result | Should Match 'None'
            $result | Should Match '64-bit'
            Assert-MockCalled Get-SystemSnapshot -Times 1 -Exactly
        }
        It 'returns a clear message when the snapshot fails' {
            Mock Get-SystemSnapshot { 'Error: test snapshot failure' }
            Get-AllClientsComputerInformation | Should Match 'Error: test snapshot failure'
        }
    }

    Describe 'Menu and validation' {
        It 'displays all nine choices' {
            $menu = Show-OSInfoMenu | Out-String
            $menu | Should Match '1. Operating System'
            $menu | Should Match '8. Get All Information'
            $menu | Should Match '9. Quit'
        }
        It 'shows an error for invalid input and exits on 9' {
            $script:inputNumber = 0
            Mock Read-Host {
                $script:inputNumber++
                if ($script:inputNumber -eq 1) { 'X' } else { '9' }
            }
            $output = Start-OSInfoProgram | Out-String
            $output | Should Match 'Invalid selection'
            $output | Should Match 'Exiting program'
            Assert-MockCalled Read-Host -Times 2 -Exactly
        }
    }
}
