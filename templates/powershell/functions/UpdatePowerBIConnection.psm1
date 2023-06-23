function Update-PowerBIConnection {

    [CmdletBinding()]
    param (
        [string]$ConnectionsToReplaceParameters,
        [string]$Environment,
        [guid]$ReportId,
        [guid]$WorkspaceId
    )

    $connectionsToReplace = Get-Content "$connectionsToReplaceParameters" | ConvertFrom-Json
    $replaceConnections = $connectionsToReplace.Where( {$_.environment -eq $environment} ).connectionsToReplace
    $numberOfConnectionsToReplace = $replaceConnections.Count

    if ( $numberOfConnectionsToReplace -eq 0 ) {
        Write-Host "No parameters found for the $environment environment. Skipping update of datasources."

        return;
    }

    Write-Host "Found $numberOfConnectionsToReplace parameters for the $environment environment. Checking which datasources need updates."

    $reportDatasetId = ( Get-PowerBIReport `
        -Id $reportId `
        -WorkspaceId $workspaceId `
        | Select-Object -Property DatasetId ).DatasetId

    $reportDatasources = Get-PowerBIDatasource `
        -DatasetId $reportDatasetId  `
        -WorkspaceId $workspaceId `
        | Select-Object -Property DatasourceType, ConnectionDetails

    $updateDetails = @()

    foreach ( $connection in $replaceConnections ) {
        $datasourceType = $connection.replace.DatasourceType
        $toReplace = $connection.replace.ConnectionDetails
        $toReplaceWith = $connection.replaceWith.connectionDetails

        if (
            $reportDatasources.ConnectionDetails.Where({ (ConvertTo-Json $_) -eq (ConvertTo-Json $toReplace) }, 'First').Count -gt 0
        ) {
            Write-Host "$datasourceType connection:" 
            Write-Output $toReplace 
            Write-Host "Replace with:" 
            Write-Output $toReplaceWith 

            $updateDetails += @(
                    @{            
                        datasourceSelector = @{
                            datasourceType = $datasourceType ;
                            connectionDetails = $toReplace
                        } ;
                        connectionDetails = $toReplaceWith
                    }
                )
        }
    }

    if ( $updateDetails.Count -eq 0 ) {
        Write-Host "No differences found between connections in report and parameters. Skipping update of datasources."

        return;
    }

    $updateBody = @{ updateDetails = @( $updateDetails ) } | ConvertTo-Json -Depth 7

    Write-Host "##[group]Update dataset with id: $reportDatasetId"
    Write-Output $updateBody
    Write-Host "##[endgroup]"

    Invoke-PowerBIRestMethod `
        -Url "groups/$workspaceId/datasets/$reportDatasetId/Default.UpdateDatasources" `
        -Method POST `
        -Body $updateBody

    Write-Host "Triggering a Refresh of the Dataset now that connections have been changed."
    
    Invoke-PowerBIRestMethod `
        -Url "groups/$workspaceId/datasets/$reportDatasetId/refreshes" `
        -Method POST
}

Export-ModuleMember -Function Update-PowerBIConnection
