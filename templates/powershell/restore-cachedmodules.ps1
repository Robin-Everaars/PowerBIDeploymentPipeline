param (
    $Path
)
if (-not (Test-Path -Path $Path) ) {
    $null = New-Item -Path $Path -ItemType Directory
}
Save-Module -Name MicrosoftPowerBIMgmt.Profile -Path $Path
Save-Module -Name MicrosoftPowerBIMgmt.Workspaces -Path $Path
Save-Module -Name MicrosoftPowerBIMgmt.Reports -Path $Path
Save-Module -Name MicrosoftPowerBIMgmt.Data -Path $Path
Save-Module -Name AzureAD -RequiredVersion 2.0.1.16 -Path $Path # Must be specifically this version or a conflict with the used Newtonsoft version will occur with the PBI modules. For reference, see: https://github.com/microsoft/powerbi-powershell/issues/98