<#
.SYNOPSIS
Deploys monitoring - dashboard for resources

.DESCRIPTION
Deploys monitoring - dashboard for resources

.PARAMETER ResourceGroupName
The resource group where all deployments will reside

.PARAMETER Location
The deployment region

.EXAMPLE
Deploy-AzDashboards -ResourceGroupName <some-name-rg>

.NOTES
Deploy using ARM templates
#>

function Deploy-AzDashboards {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [string] $ResourceGroupName
    )

    begin {
        Write-Debug ("[{0} entered]" -f $MyInvocation.MyCommand)

        $null = Get-AzContext -ErrorAction Stop
    }

    process {
        $paths = (Get-ChildItem -Path "./monitoring" -Recurse -Filter "*.dashboard.json").FullName

        Write-Verbose 'Starting alerts/dashboard deployments...' -Verbose

        foreach ($path in $paths) {
           $deploymentInputsArgs = @{
               TemplateFile = "$path"
               Verbose      = $true
               ErrorAction  = "Stop"
           }

           # Perform actual deployment of alerts or dashboard
           Write-Verbose 'Handling resource group level deployment' -Verbose
           $result = New-AzResourceGroupDeployment @deploymentInputsArgs -ResourceGroupName $ResourceGroupName -ErrorVariable ErrorMessages

           # Display error messages from Azure
           if ($ErrorMessages) {
            Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
           }
           else {
              if ($result.Outputs) {
                   foreach ($outputkey in $result.Outputs.Keys) {
                       Write-Verbose ("Set [{0}] deployment output as pipeline environment variable with value: [{1}]" -f $outputkey, $result.Outputs[$outputkey].Value) -Verbose
                       Write-Host ("##vso[task.setvariable variable={0};isOutput=true]{1}" -f $outputkey, $result.Outputs[$outputkey].Value)
                   }
              }

              Write-Verbose "Deployment successful" -Verbose
           }
        }
    }

    end {
        Write-Debug ("[{0} existed]" -f $MyInvocation.MyCommand)
    }
}
