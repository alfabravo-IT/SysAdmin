# ☁️ Enable Azure Arc for SQL Server

---

## 📋 Prerequisites

### 🖥️ On the Server

- **OS:** Windows Server 2012 R2 or later  
- **SQL Server:** 2012 or later  
- **.NET Framework:** 4.7.2 or later  
- **Privileges:** Local Administrator  
- **Internet Access:** Ensure outbound connectivity on port **443** to the following endpoints:

| Endpoint | Purpose | When Required |
|----------|---------|--------------|
| `download.microsoft.com` | Download Windows installation package | Installation only |
| `packages.microsoft.com` | Download Linux installation package | Installation only |
| `login.microsoftonline.com`, `*.login.microsoft.com`, `pas.windows.net` | Microsoft Entra ID | Always |
| `management.azure.com` | Azure Resource Manager | Connect/Disconnect only |
| `*.his.arc.azure.com`, `*.guestconfiguration.azure.com` | Metadata, guest config | Always |
| `guestnotificationservice.azure.com`, `*.guestnotificationservice.azure.com` | Notification service | Always |
| `azgn*.servicebus.windows.net`, `*.servicebus.windows.net` | Notification, WAC/SSH | As needed |
| `*.waconazure.com` | WAC connectivity | If using WAC |
| `*.blob.core.windows.net` | Extension downloads | Always (except private endpoints) |
| `dc.services.visualstudio.com` | Agent telemetry | Optional (not in agent 1.24+) |
| `*.<region>.arcdataservices.com` | Arc SQL Server telemetry | Always |
| `www.microsoft.com/pkiops/certs` | Cert updates for ESUs | If using ESUs |
| `dls.microsoft.com` | License validation | For Hotpatching, Azure Benefits, PayGo |

---

### ☁️ On Azure

- **Azure Subscription**
- **Permissions:** Contributor or Owner on target Resource Group
- **Resource Providers:** Register the following:
    - `Microsoft.HybridCompute`
    - `Microsoft.GuestConfiguration`
    - `Microsoft.HybridConnectivity`
    - `Microsoft.AzureArcData` (for SQL Arc)
    - `Microsoft.Compute` (for Update Manager/extensions)

#### Register Providers via PowerShell

```
Connect-AzAccount
Set-AzContext -SubscriptionId [YourSubscriptionId]
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute
Register-AzResourceProvider -ProviderNamespace Microsoft.GuestConfiguration
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridConnectivity
Register-AzResourceProvider -ProviderNamespace Microsoft.AzureArcData
```

#### Register Providers via Azure CLI

```
az account set --subscription "{Your Subscription Name}"
az provider register --namespace 'Microsoft.HybridCompute'
az provider register --namespace 'Microsoft.GuestConfiguration'
az provider register --namespace 'Microsoft.HybridConnectivity'
az provider register --namespace 'Microsoft.AzureArcData'
```

---

## 🔗 Connect SQL Server to Azure Arc

> **Note:**  
> Azure Arc automatically installs the Azure extension for SQL Server on connected servers. All SQL Server instances are registered in Azure for centralized management.

---

### 1️⃣ Onboard the Server

#### Generate the Onboarding Script

1. Go to **Azure Arc > SQL Server** and select **+ Add**  
     <img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/start-creation-of-sql-server-azure-arc-resource.png?view=sql-server-ver17" alt="Start creation" width="640"/>
2. Select **Connect Servers**
3. Review prerequisites, then **Next: Server details**
4. Specify:
     - **Subscription**
     - **Resource group**
     - **Region**
     - **Operating system**
     - *(Optional)* Proxy and custom server name  
     <img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/server-details-sql-server-azure-arc.png?view=sql-server-ver17" alt="Server details" width="640"/>
5. Select SQL Server edition and license type
6. Exclude SQL Server instances (if needed)  
     <img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/server-details-sql-server-management-azure-arc.png?view=sql-server-ver17" alt="Management details" width="640"/>
7. **Next: Tags** (optional)
8. **Run script** to generate onboarding script  
     <img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/download-script-sql-server-azure-arc.png?view=sql-server-ver17" alt="Download script" width="640"/>
9. **Download** the script

---

### 2️⃣ Connect SQL Server Instances

Run the downloaded script on the target server:

```
.\RegisterSqlServerArc.ps1
```

The script installs the Azure connected machine agent (if needed) and the Azure extension for SQL Server.

---

### 3️⃣ Validate Arc-Enabled SQL Server

Go to **Azure Arc > SQL Server** and verify the new resource.

<img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/validate-sql-server-azure-arc.png?view=sql-server-ver17" alt="Validate SQL Server" width="640"/>

---

## 🔄 Connect SQL Server on an Already Arc-Enabled Server

If your server is already Arc-enabled, install the **Azure extension for SQL Server** via the Azure Portal, PowerShell, or Azure CLI.

### Azure Portal

1. Open **Azure Arc > Servers**
2. Find your connected server
3. Under **Extensions**, select **+ Add**
4. Choose **Azure extension for SQL Server**
5. Specify edition, license, and excluded instances  
     <img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/license-type-in-extension.png?view=sql-server-ver17" alt="License type" width="640"/>
6. **Review + Create** and then **Create**

### PowerShell

```
$Settings = @{
    SqlManagement = @{ IsEnabled = $true }
    ExcludedSqlInstances = @("MSSQLSERVER01","MSSQLSERVER")
    LicenseType = "<License Type>"
}
New-AzConnectedMachineExtension -Name "WindowsAgent.SqlServer" `
    -ResourceGroupName {your resource group name} `
    -MachineName {your machine name} `
    -Location {azure region} `
    -Publisher "Microsoft.AzureData" `
    -Settings $Settings `
    -ExtensionType "WindowsAgent.SqlServer"
```

### Azure CLI

```
az connectedmachine extension create \
    --machine-name "{your machine name}" \
    --location "{azure region}" \
    --name "WindowsAgent.SqlServer" \
    --resource-group "{your resource group name}" \
    --type "WindowsAgent.SqlServer" \
    --publisher "Microsoft.AzureData" \
    --settings "{\"SqlManagement\":{\"IsEnabled\":true}, \"LicenseType\":\"<License Type>\", \"ExcludedSqlInstances\":[]}"
```

---

### ✅ Validate

Go to **Azure Arc > SQL Server** and confirm the SQL Server resource is registered.

<img src="https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/media/join/validate-sql-server-azure-arc.png?view=sql-server-ver17" alt="Validate SQL Server" width="640"/>

---

> ℹ️ **Tip:**  
> The Azure extension for SQL Server continuously monitors for new instances and automatically registers them with Azure Arc.

---