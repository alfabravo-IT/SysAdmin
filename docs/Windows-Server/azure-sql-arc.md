# 📘 Configurazione di SQL Server on-premises con Azure Arc

Questa guida descrive la procedura dettagliata per collegare un'istanza di SQL Server in esecuzione su Windows Server a **Azure Arc**, permettendo la gestione da Azure Portal come risorsa ibrida.

---

## ✅ Requisiti

### 📡 Requisiti di rete (uscita dal server verso internet)

| Tipo     | Destinazione                           | Porta | Protocollo |
|----------|----------------------------------------|-------|------------|
| DNS      | *.azure.com, *.microsoft.com           | 53    | UDP/TCP    |
| HTTPS    | *.azmk8s.io, *.azure-automation.net, *.blob.core.windows.net, *.azureedge.net, *.monitor.azure.com, *.login.microsoftonline.com | 443 | TCP        |

> Se è presente un proxy aziendale, è necessario configurarlo in Windows (`netsh winhttp set proxy`) o usarlo nei comandi `az`.

---

### 💻 Requisiti sul server Windows

- Windows Server 2016 o superiore
- SQL Server 2012 o superiore
- Account locale amministratore
- Accesso a Internet
- PowerShell 5.1+
- Permessi `sysadmin` sull'istanza SQL Server
- Azure CLI installata
- Azure Connected Machine Agent installabile

---

### ☁️ Requisiti su Azure

- Sottoscrizione Azure attiva
- Permessi per registrare risorse Azure Arc
- Gruppo di risorse
- Regione supportata da Azure Arc (es. `westeurope`)

---

## ⚙️ Procedura dettagliata

---

### 🥇 1. Installare Azure CLI

Aprire PowerShell **come amministratore** ed eseguire:

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

Verifica l’installazione:

```powershell
az version
```

---

### 🥈 2. Autenticarsi su Azure

```powershell
az login
```

Se hai più sottoscrizioni:

```powershell
az account set --subscription "NOME_TUA_SOTTOSCRIZIONE"
```

---

### 🥉 3. Installare Azure Connected Machine Agent

```powershell
$agentUrl = "https://aka.ms/AzureConnectedMachineAgent"
Invoke-WebRequest -Uri $agentUrl -OutFile ".\AzureConnectedMachineAgent.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/i AzureConnectedMachineAgent.msi /quiet"
```

---

### 🏅 4. Connettere il server a Azure Arc

```powershell
az connectedmachine connect `
  --resource-group NOME-RG `
  --location westeurope `
  --name NOME-LOGICO-SERVER `
  --tags "env=onprem" "managedBy=arc"
```

---

### 🧩 5. Aggiungere l'estensione SQL Server

```powershell
az connectedmachine extension create `
  --machine-name NOME-LOGICO-SERVER `
  --name Microsoft.AzureData.SqlServer `
  --resource-group NOME-RG `
  --location westeurope `
  --publisher Microsoft.AzureData `
  --type SqlServer `
  --type-handler-version 1.0 `
  --settings '{}'
```

---

### 🧪 6. Registrare SQL Server su Azure Arc

Scarica lo script ufficiale:

```powershell
Invoke-WebRequest -Uri https://aka.ms/arc-sql/onboarding-script -OutFile .\EnableSQLArc.ps1
```

Esegui lo script:

```powershell
.\EnableSQLArc.ps1 `
  -azureResourceGroup "NOME-RG" `
  -azureRegion "westeurope" `
  -sqlInstanceName "NOME-ISTANZA-SQL" `
  -useWindowsAuthentication
```

> Per istanze named o porte personalizzate:
> Aggiungi `-sqlInstance "NOME\ISTANZA"` e `-sqlInstancePort 1433`

---

## ✅ Verifica su Azure

1. Vai su **Azure Portal**
2. Naviga in **Azure Arc > Server**
3. Verifica che il server sia registrato
4. Verifica che in **SQL Server – Azure Arc** sia visibile l’istanza SQL, versione, configurazione e stato

---

## 🎁 Extra (opzionali)

### 🔐 Azure Key Vault Integration
Per archiviare e usare segreti (es. stringhe connessione).

### 📊 Azure Monitor e Defender for SQL
Per abilitare monitoraggio, sicurezza e auditing centralizzati via Azure.

---

## 📌 Note finali

- La registrazione via Azure Arc **non sposta** il database nel cloud
- Puoi usufruire dell’**Azure Hybrid Benefit**
- Puoi applicare **policy, compliance e automazioni** su SQL locale come su SQL cloud

---
