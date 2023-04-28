param (
    $BuildSourcesDirectory,
    $BuildArtifactStagingDirectory
)

Write-Host "Checking for changed Power BI reports"
$changedFiles = git diff --name-only HEAD^ HEAD -- 'reports/*' | Where-Object { $_ -like '*.pbix' }

$filesChanged = $changedFiles -split '\r?\n' | Where-Object { $_ -like '*.pbix' }

$hasPbixFiles = $filesChanged.Count -gt 0
Write-Host "##vso[task.setvariable variable=FilesChanged;isOutput=true;]$hasPbixFiles"

if ( $hasPbixFiles ) {
    Write-Host "##[section]"$filesChanged.Count "Change(s) found, see changed file(s) below"
    Write-Output $changedFiles

    Write-Host "Copying changed Power BI files to staging directory"
    foreach ( $changedReport in $changedFiles) { 
        $sourceFix = $changedReport.replace("/", "\")

        $folderPath = ($sourceFix.Split("\",3) | Select-Object -Index 0,1) -join "\"

        $target = $BuildArtifactStagingDirectory + "/" + $folderPath

        $sourceFolder = $BuildSourcesDirectory + "/" + $sourceFix

        if ( !(Test-Path -path $target) ) { # Create the target folder if it doesn't exist
            New-Item -Path $target -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $sourceFolder -Destination $target | Out-Null
    }

    # Copy dependencies
    Write-Host "Copying dependencies to staging directory"
    $powerShellFilePath = "pipelines\power-bi\templates\powershell"
    $sourcePath = "D:\a\1\s\" + $powerShellFilePath
    $destinationPath = $BuildArtifactStagingDirectory + "\" + $powerShellFilePath
    Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse
}
else {
	Write-Host "##[section]No Power BI changes detected"
}