# Enable Azure Arc for SQL Server
## Prerequisites

**On the Server**

- Windows Server 2012 R2 or later  
- SQL Server 2012 or later  
- .NET Framework 4.7.2 or later  
- Local Administrator privileges  
- Internet access (Ensure the server can reach the endpoints below on port **443**):

| Agent Resource | Description | When Required |
|----------------|-------------|----------------|
| `download.microsoft.com` | Used to download the Windows installation package | At installation time only |
| `packages.microsoft.com` | Used to download the Linux installation package | At installation time only |
| `login.microsoftonline.com` | Microsoft Entra ID | Always |
| `*.login.microsoft.com` | Microsoft Entra ID | Always |
| `pas.windows.net` | Microsoft Entra ID | Always |
| `management.azure.com` | Azure Resource Manager – to create or delete the Arc server resource | When connecting or disconnecting a server only |
| `*.his.arc.azure.com` | Metadata and hybrid identity services | Always |
| `*.guestconfiguration.azure.com` | Extension management and guest configuration services | Always |
| `guestnotificationservice.azure.com` <br> `*.guestnotificationservice.azure.com` | Notification service for extension and connectivity scenarios | Always |
| `azgn*.servicebus.windows.net` | Notification service for extension and connectivity scenarios | Always |
| `*.servicebus.windows.net` | For Windows Admin Center and SSH scenarios | If using SSH or Windows Admin Center from Azure |
| `*.waconazure.com` | For Windows Admin Center connectivity | If using Windows Admin Center |
| `*.blob.core.windows.net` | Download source for Azure Arc-enabled server extensions | Always (except when using private endpoints) |
| `dc.services.visualstudio.com` | Agent telemetry | Optional (not used in agent versions 1.24+) |
| `*.<region>.arcdataservices.com` | For Arc SQL Server (Sends data processing service, service telemetry, and performance monitoring to Azure) <br> Allows TLS 1.2 or 1.3 only | Always |
| `www.microsoft.com/pkiops/certs` | Intermediate certificate updates for ESUs (uses HTTP/TCP 80 and HTTPS/TCP 443) | Required if using ESUs enabled by Azure Arc |
| `dls.microsoft.com` | Used by Arc machines to perform license validation | Required when using Hotpatching, Windows Server Azure Benefits, or Windows Server PayGo on Arc-enabled machines |

---

**On Azure**

- An **Azure Subscription**
- **Permissions**: Contributor or Owner role in the target Resource Group
- **Resource Provider Registration**:
	1. Go to **Subscriptions**  
	2. Select your subscription  
	3. Click **Resource providers**  
	4. Search for the following:
	   - `Microsoft.HybridCompute`
	   - `Microsoft.GuestConfiguration`
	   - `Microsoft.HybridConnectivity`
	   - `Microsoft.AzureArcData` (if you plan to Arc-enable SQL Servers)
	   - `Microsoft.Compute` (for Azure Update Manager and automatic extension upgrades)  
	5. If any are **Not Registered**, click **Register**


PowerShell

```
Connect-AzAccount
Set-AzContext -SubscriptionId [subscription you want to onboard]
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute
Register-AzResourceProvider -ProviderNamespace Microsoft.GuestConfiguration
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridConnectivity
Register-AzResourceProvider -ProviderNamespace Microsoft.AzureArcData
```

Azure CLI

```
az account set --subscription "{Your Subscription Name}"
az provider register --namespace 'Microsoft.HybridCompute'
az provider register --namespace 'Microsoft.GuestConfiguration'
az provider register --namespace 'Microsoft.HybridConnectivity'
az provider register --namespace 'Microsoft.AzureArcData'
```

# Connect your SQL Server to Azure Arc
**Important**
Azure Arc automatically installs the Azure extension for SQL Server when a server connected to Azure Arc has SQL Server installed. All the SQL Server instance resources are automatically created in Azure, providing a centralized management platform for all your SQL Server instances.

## Onboard the server to Azure Arc

If the server that runs your SQL Server instance isn't yet connected to Azure, you can initiate the connection from the target machine using the onboarding script. This script connects the server to Azure and installs the Azure extension for SQL Server.

### Generate an onboarding script for SQL Server

1.  Go to **Azure Arc > SQL Server** and select **\+ Add**
    
    ![Screenshot of the start creation.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/start-creation-of-sql-server-azure-arc-resource.png?view=sql-server-ver17)
    
2.  Under **Connect SQL Server to Azure Arc**, select **Connect Servers**
    
3.  Review the prerequisites and select **Next: Server details**
    
4.  Specify:
    
    -   **Subscription**
    -   **Resource group**
    -   **Region**
    -   **Operating system**
    
    If necessary, specify the proxy your network uses to connect to the Internet.
    
    To use a specific name for Azure Arc enabled Server instead of default host name, users can add the name for Azure Arc enabled Server in **Server Name**.
    
    ![Screenshot of server details for Azure Arc.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/server-details-sql-server-azure-arc.png?view=sql-server-ver17)
    
5.  Select the SQL Server edition and license type you are using on this machine. Some Arc-enabled SQL Server features are only available for SQL Server instances with Software Assurance (Paid) or with Azure pay-as-you-go. 
    
6.  Specify the SQL Server instance(s) you want to exclude from registering (if you have multiple instances installed on the server). Separate each excluded instance by a space.
    
      ![Screenshot of server management details.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/server-details-sql-server-management-azure-arc.png?view=sql-server-ver17)
    
7.  Select **Next: Tags** to optionally add tags to the resource for your SQL Server instance.
    
8.  Select **Run script** to generate the onboarding script. Screenshot of
    
    ![Screenshot of a download script.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/download-script-sql-server-azure-arc.png?view=sql-server-ver17)
    
9.  Select **Download** to download the script to your machine.
    
### Connect SQL Server instances to Azure Arc

In this step, execute the script you downloaded from the Azure portal, on the target machine. The script installs Azure extension for SQL Server. If the machine itself doesn't have the Azure connected machine agent installed, the script installs it first, then install the Azure extension for SQL Server. Azure connected machine agent registers the connected server as an Azure resource of type `Server - Azure Arc`, and the Azure extension for SQL Server connects the SQL Server instances as an Azure resource of type `SQL Server - Azure Arc`.

**Powershell**
1.  Launch an admin instance of **powershell.exe** 
    
2.  Execute the downloaded script.
    ```
      .\RegisterSqlServerArc.ps1    
    ```
      
## Validate your Arc-enabled SQL Server resources

Go to **Azure Arc > SQL Server** and open the newly registered Arc-enabled SQL Server resource to validate.

![Screenshot of validating a connected SQL Server.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/validate-sql-server-azure-arc.png?view=sql-server-ver17)

# Connect your SQL Server to Azure Arc on a server already enabled by Azure Arc

**Important**
Azure Arc automatically installs the Azure extension for SQL Server when a server connected to Azure Arc has SQL Server installed. All the SQL Server instance resources are automatically created in Azure, providing a centralized management platform for all your SQL Server instances.

If the machine with SQL Server is already connected to Azure Arc, to connect the SQL Server instances, install _Azure extension for SQL Server_. The extension is in the extension tab of "Server -Azure Arc" resource as **Azure Extension for SQL Server**.

**Important**
The Azure resource with type `SQL Server - Azure Arc` representing the SQL Server instance installed on the machine uses the same region and resource group as the Azure resources for Arc-enabled servers.

## Connect

**Azure Portal**
To install the Azure extension for SQL Server, use the following steps:

1.  Open the **Azure Arc > Servers** resource.
2.  Search for the connected server with the SQL Server instance that you want to connect to Azure.
3.  Under **Extensions**, select **\+ Add**.
4.  Select `Azure extension for SQL Server` and select **Next**.
5.  Specify the SQL Server edition and license type you are using on this machine. Some Arc-enabled SQL Server features are only available for SQL Server instances with Software Assurance (Paid) or with Azure pay-as-you-go. 
6.  Specify the SQL Server instance(s) you want to exclude from registering (if you have multiple instances to skip, separate them by spaces) and select **Review + Create**. ![Screenshot for license type and exclude instances.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/license-type-in-extension.png?view=sql-server-ver17)
7.  Select **Create**.

**Powershell**
To install _Azure extension for SQL Server_, run:
```
$Settings = @{ SqlManagement = @{ IsEnabled = $true }; ExcludedSqlInstances = @(<Comma separated names of SQL Server instances, eg: "MSSQLSERVER01","MSSQLSERVER">); LicenseType="<License Type>"}
    
New-AzConnectedMachineExtension -Name "WindowsAgent.SqlServer" -ResourceGroupName {your resource group name} -MachineName {your machine name} -Location {azure region} -Publisher "Microsoft.AzureData" -Settings $Settings -ExtensionType "WindowsAgent.SqlServer"
```    
**Azure CLI**
To install _Azure extension for SQL Server_ for Windows Operating System, run:
```
az connectedmachine extension create --machine-name "{your machine name}" --location "{azure region}" --name "WindowsAgent.SqlServer" --resource-group "{your resource group name}" --type "WindowsAgent.SqlServer" --publisher "Microsoft.AzureData" --settings "{\"SqlManagement\":{\"IsEnabled\":true}, \"LicenseType\":\"<License Type>\", \"ExcludedSqlInstances\":[]}"
```    

Once installed, the Azure extension for SQL Server recognizes all the installed SQL Server instances and connects them with Azure Arc.

The extension runs continuously to detect changes in the SQL Server configuration. For example, if a new SQL Server instance is installed on the machine, the extension automatically detects and registers it with Azure Arc. 

## Validate your Arc-enabled SQL Server resources

Go to **Azure Arc > SQL Server** and open the newly registered Arc-enabled SQL Server resource to validate.

![Screenshot of validating a connected SQL Server.](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/validate-sql-server-azure-arc.png?view=sql-server-ver17)
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEzMjkwMjIxOTIsLTE4NDM3MDcwNDBdfQ
==
-->