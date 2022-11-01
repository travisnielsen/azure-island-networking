<#
.SYNOPSIS
Configures diagnostics settings on resources

.DESCRIPTION
Configures diagnostics settings on resources

.PARAMETER WorkspaceResourceGroup
The resource group where your log analytics workspace resides

.EXAMPLE
Deploy-AzMonitoring -WorkspaceResourceGroup <some-name-rg>

.NOTES

#>
function Deploy-AzDiagnostics {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [string] $WorkspaceResourceGroup
    )

    begin {
        Write-Debug ("[{0} entered]" -f $MyInvocation.MyCommand)

        # Set appropriate subscription context
        $null = Get-AzContext -ErrorAction Stop
    }

    process {
        # Lets validate the workspace information
        Write-Verbose "Getting Log analytics workspace information..."
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WorkspaceResourceGroup -ErrorAction Stop
        if ($workspace) {
            $workspaceId = $workspace.ResourceId
        }
        else {
            Write-Error "Failed to find resource group - $WorkspaceResourceGroup" -ErrorAction Stop
        }

        Write-Verbose "Work space resource Id - $workspaceId"

        # Currently, we are only configuring monitoring for these resource types
        $validResourceTypes = @(
            "Microsoft.Insights/components",
            "Microsoft.DataFactory/factories",
            "Microsoft.Network/azureFirewalls",
            "Microsoft.Sql/servers/databases"
        )

        foreach ($type in $validResourceTypes) {
            Write-Verbose "Querying resources for resource type - $type" -Verbose

            $getResource = Get-AzResource | Where-Object { $_.ResourceType -like $type }
            foreach ($resource in $getResource) {
                $resourceId = $resource.ResourceId

                Write-Verbose "Enabling disgnostics settings on resource - $resourceId" -Verbose

                # This will enable all disgnostics settings on a resource if Enabled=$true
                $diagSettingsArgs = @{
                    Name        = 'toLogAnalytics'
                    ResourceId  = $resourceId
                    WorkspaceId = $workspaceId
                    Enabled     = $true
                }

                Write-Debug ($diagSettingsArgs | Format-Table | Out-String) -Verbose

                Set-AzDiagnosticSetting  @diagSettingsArgs -ErrorAction Continue
            }
        }
    }

    end {
        Write-Debug ("[{0} existed]" -f $MyInvocation.MyCommand)
    }
}
