# 📘 Configuring On-premises SQL Server with Azure Arc

This guide provides a step-by-step procedure to connect a SQL Server instance running on Windows Server to **Azure Arc**, enabling management from the Azure Portal as a hybrid resource.

---

## ✅ Requirements

### 📡 Network Requirements (outbound from server to internet)

| Type     | Destination                           | Port | Protocol |
|----------|---------------------------------------|------|----------|
| DNS      | *.azure.com, *.microsoft.com          | 53   | UDP/TCP  |
| HTTPS    | *.azmk8s.io, *.azure-automation.net, *.blob.core.windows.net, *.azureedge.net, *.monitor.azure.com, *.login.microsoftonline.com | 443 | TCP      |

> If a corporate proxy is present, configure it in Windows (`netsh winhttp set proxy`) or use it with `az` commands.

---

### 💻 Requirements on the Windows Server

- Windows Server 2016 or later
- SQL Server 2012 or later
- Local administrator account
- Internet access
- PowerShell 5.1+
- `sysadmin` permissions on the SQL Server instance
- Azure CLI installed
- Azure Connected Machine Agent installable

---

### ☁️ Requirements on Azure

- Active Azure subscription
- Permissions to register Azure Arc resources
- Resource group
- Azure Arc supported region (e.g., `westeurope`)

---

## ⚙️ Step-by-step Procedure

---

### 🥇 1. Install Azure CLI

Open PowerShell **as administrator** and run:

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

Verify the installation:

```powershell
az version
```

---

### 🥈 2. Authenticate to Azure

```powershell
az login
```

If you have multiple subscriptions:

```powershell
az account set --subscription "YOUR_SUBSCRIPTION_NAME"
```

---

### 🥉 3. Install Azure Connected Machine Agent

```powershell
$agentUrl = "https://aka.ms/AzureConnectedMachineAgent"
Invoke-WebRequest -Uri $agentUrl -OutFile ".\AzureConnectedMachineAgent.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/i AzureConnectedMachineAgent.msi /quiet"
```

---

### 🏅 4. Connect the Server to Azure Arc

```powershell
az connectedmachine connect `
  --resource-group RESOURCE-GROUP-NAME `
  --location westeurope `
  --name LOGICAL-SERVER-NAME `
  --tags "env=onprem" "managedBy=arc"
```

---

### 🧩 5. Add the SQL Server Extension

```powershell
az connectedmachine extension create `
  --machine-name LOGICAL-SERVER-NAME `
  --name Microsoft.AzureData.SqlServer `
  --resource-group RESOURCE-GROUP-NAME `
  --location westeurope `
  --publisher Microsoft.AzureData `
  --type SqlServer `
  --type-handler-version 1.0 `
  --settings '{}'
```

---

### 🧪 6. Register SQL Server with Azure Arc

Download the official script:

```powershell
Invoke-WebRequest -Uri https://aka.ms/arc-sql/onboarding-script -OutFile .\EnableSQLArc.ps1
```

Run the script:

```powershell
.\EnableSQLArc.ps1 `
  -azureResourceGroup "RESOURCE-GROUP-NAME" `
  -azureRegion "westeurope" `
  -sqlInstanceName "SQL-INSTANCE-NAME" `
  -useWindowsAuthentication
```

> For named instances or custom ports:
> Add `-sqlInstance "NAME\INSTANCE"` and `-sqlInstancePort 1433`

---

## ✅ Verification on Azure

1. Go to **Azure Portal**
2. Navigate to **Azure Arc > Servers**
3. Verify that the server is registered
4. Check that under **SQL Server – Azure Arc** the SQL instance, version, configuration, and status are visible

---

## 🎁 Extra (optional)

### 🔐 Azure Key Vault Integration
To store and use secrets (e.g., connection strings).

### 📊 Azure Monitor and Defender for SQL
To enable centralized monitoring, security, and auditing via Azure.

---

## 📌 Final Notes

- Registration via Azure Arc **does not move** the database to the cloud
- You can benefit from **Azure Hybrid Benefit**
- You can apply **policy, compliance, and automation** to on-prem SQL just like cloud SQL

---
