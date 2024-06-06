# Power BI Deployment Pipeline

## Description

The Power BI Deployment Pipeline enables the deployment of Power BI reports hosted in Git (Azure Repos or GitHub) via Azure DevOps pipelines. While the out-of-the-box pipeline embedded in the Power BI Service is tailored for citizen developers, this pipeline aligns Power BI reporting with common IT best practices.

## Features

- Selective Deployment: The pipeline uses git diff to detect changes and only deploys modified reports.
- Workspace-Based Deployment: Reports are deployed to workspaces matching the folder names under the "reports" directory.
- Parameterized Connections: A JSON parameters file allows connection settings to be replaced and configured for development, testing, and production environments.

## Requirements

- Azure DevOps Project: Ensure you have an active Azure DevOps project.
- Service Principal/Connection: Admin access to the workspace(s) is required for deployment.

## Set-up

1. Copy Repository Contents: Clone or download the repository contents to your local machine.
2. Create Service Connection: Set up a service connection with the correct API permissions in Azure DevOps.
3. Power BI REST API: Ensure the service principal can utilize the  Power BI REST APIs.
4. Create "reports" Folder: In the root of the project, create a folder named "reports" with subfolders that match the names of the workspaces to deploy to.

## Usage

1. Make changes to your Power BI reports and commit them to the repository.
2. Close a pull request, and the pipeline will automatically detect changes and handle the deployment.

## Configuration

- Configure any connections that need to be changed in templates/powershell/parameters/connections-to-swap.json

## License

This project is licensed under the MIT License. See the LICENSE file for details.