param (
	$artifactName,
	$workspaceNameSuffix = '',
	$environment,
	$updatePowerBIDatasources
)

if ( $workspaceNameSuffix -eq 'null' ) {
	$workspaceNameSuffix = ''
}

$ErrorActionPreference = "Stop"

$Env:PSModulePath = "D:\a\1\s\powershellmodules", $Env:PSModulePath -join [System.IO.Path]::PathSeparator
Import-Module MicrosoftPowerBIMgmt.Profile
Import-Module MicrosoftPowerBIMgmt.Workspaces
Import-Module MicrosoftPowerBIMgmt.Reports
Import-Module MicrosoftPowerBIMgmt.Data
Import-Module AzureAD -RequiredVersion 2.0.1.16
Import-Module -Name $PSScriptRoot\functions\UpdatePowerBIConnection.psm1 -Verbose -Force

## ------------------------------------------------------
## 1. Sign in with Service Principal
## ------------------------------------------------------
Write-Host "##[section]Sign in with Service Principal"

$clientsec = "$env:clientsecret" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:clientId, $clientsec
$tenant = "$env:tenantId"

try {
	Connect-PowerBIServiceAccount `
		-ServicePrincipal `
		-Credential $credential `
		-TenantId $tenant
} catch {
	Write-Host "##[error]Could not login with service account. Please see the error details below."
	Write-Output $_.Exception
	Resolve-PowerBIError
	Throw
}

Write-Host "##[section]Succesfully Signed in with Service Principal";

## ------------------------------------------------------
## 2. Deploy changed reports
## ------------------------------------------------------
$artifactFolder = "D:\a\1\" + $artifactName + "\reports\"
$workspaces = Get-ChildItem -Path $artifactFolder -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

foreach ($workspace in $workspaces) {

	$workspaceName = $workspace.FullName.Replace($artifactFolder , "") 
	$workspaceNameWithSuffix = $workspaceName + $workspaceNameSuffix

	Write-Host "##[section]Checking if workspace $workspaceNameWithSuffix exists";

	try {
		$workspaceNameWithSuffix = $workspaceNameWithSuffix.ToLower()
		$pbiWorkspace = Get-PowerBIWorkspace -Filter "tolower(name) eq '$workspaceNameWithSuffix'" -First 1

		if ( $null -eq $pbiWorkspace ) {
			Write-Host "[##error]Workspace '$workspaceNameWithSuffix' could not be found."
	
			throw
		}
	} catch {
		Write-Host "##[error]Could not get Power BI Workspace. Please see the error details below."
		Write-Output $_.Exception
		Resolve-PowerBIError
		Throw
	}

	Write-Host "##[section]Found workspace below";
	Write-Output $pbiWorkspace

	$reportsInFolder = Get-ChildItem -Path $workspace.FullName -Recurse | Where-Object {$_.name -like "*.pbix"} | Select-Object Name

	foreach ($report in $reportsInFolder) {
		Write-Host "##[section]Deploying Power BI report:" $report.Name

		$filePath = "D:\a\1\$artifactName\reports\$workspaceName\" + $report.Name

		try {
			$deployedReport = New-PowerBIReport `
				-Path $filePath `
				-Name $report.Name.Replace(".pbix" , "") `
				-ConflictAction "CreateOrOverwrite" `
				-Workspace $pbiWorkspace
		} catch {
			Write-Host "##[error]Could not deploy Power BI report. Please see the error details below."
			Write-Output $_.Exception
			Resolve-PowerBIError
			Throw
		}

		Write-Output $deployedReport
		
		if ( $updatePowerBIDatasources ) {
			Write-Host "Changing connections for $environment environment"

			$connectionsToReplaceParameters = "D:\a\1\$artifactName\pipelines\power-bi\templates\powershell\parameters\connections-to-swap.json"
			$workspaceId = $pbiWorkspace.Id
			$reportId = $deployedReport.Id

			Write-Host "Environment: $environment"
			Write-Host "Parameters: $connectionsToReplaceParameters"
			Write-Host "WorkspaceId: $workspaceId"
			Write-Host "ReportId: $reportId"
			
			try {
				Update-PowerBIConnection ` # Definition can be found in functions/UpdatePowerBIConnection.psm1
					-ConnectionsToReplaceParameters $connectionsToReplaceParameters `
					-Environment $environment `
					-ReportId $reportId `
					-WorkspaceId $workspaceId
			} catch {
				Write-Host "##[error]Could not update Power BI connection. Please see the error details below."
				Write-Output $_.Exception
				Resolve-PowerBIError
				Throw
			}
		}
		else {
			Write-Host "Update connections parameter set to false. Skipped update of datasources."
		}

		Write-Host "##[section]Deploying of Power BI report" $report.Name "completed";
	}
}