# Monitoring

## Enabling Diagnostics

Resource diagnostics settings can be enalbed in scale for the critical resource types. This is powered by a PowerShell script to enable all platform metrics and logs.

You will need to run the `Deploy-AzDiagnostics.ps1` script with along with all appropriate parameters to have diagnostics settings enabled.

> **NOTE**
>
> Currently, diagnostics settings is only supported on the following resource types:
> ```powershell
>$validResourceTypes = @(
>    "Microsoft.Insights/components",
>    "Microsoft.DataFactory/factories",
>    "Microsoft.Network/azureFirewalls",
>    "Microsoft.Sql/servers/databases"
>)
>```
> Other resoruce types will be onboarded at a later date.

## Alerts

Alerts will be deployed along with it's respective related resource via the ARM templates. Currently, we are only working with a subset of alerts (~3 per critical resources).

Below is a list of alerts per resource:

### Azure Firewall

- FirewallHealth
- ApplicationRuleHit
- NetworkRuleHit

### Azure SQL

- dwu_used
- connection_failed
- cpu_percent

### Data factory

- ActivityFailedRuns
- PipelineFailedRuns
- TriggerFailedRuns

### Application Insights

- Smart detection: this is enabled by default. Learn [more](https://docs.microsoft.com/en-us/azure/azure-monitor/app/proactive-arm-config#smart-detection-rule-names)

### Azure Bastion


## Dashboards

For this POC environemnt, Azure dashbaords are being used for visualization purposes. While some resources already come with full felged dashboards upon deployment, others do not. So, are developing custom dashboards using Azure workbooks for resources that do not currenly support this natively.

| Resource | Workbook features | Location |
| --- | --- | --- |
| Data Factory | Pipeline, activity, trigger runs, Errors | Azure Monitor |
| Azure Firewall |  | Azure Monitor |
| Azure SQL db | CPU, DTW (utilization), failures | Azure Monitor |
| Application insights | Availability, Failure, Performance, Usage | Azure monitor |
| Virtual machines | Insights - Performance, Metrics (CPU, Disk, Network | Azure monitor |
| Network | Network health, Connectivity, Traffic | Azure monitor |
| Storage accounts | Transactions, Latency, Client Errors | Azure monitor |
| Log analytics | Workspace usage | Azure monitor |

## Monitoring pipeline

A standalone pipeline has been created for testing the Monitoring components. It works similarly to what's documented in the root [README.md](../README.md).
To run the pipeline, simply create a PR and enter `/monitoring` in the comment section. This will auto-trigger the pipeline.
