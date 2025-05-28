# 📜 Standalone Root CA Installation and Configuration

This document describes how to install the **Active Directory Certificate Services (ADCS)** role, configure a **standalone Root Certification Authority (CA)**, export the root certificate, and provides instructions for distributing it via **Group Policy Object (GPO)**.

---

## 🛠️ 1. Installing the ADCS Role

The following command installs the **Active Directory Certificate Services** role and its management tools.

```powershell
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
```

---

## 🏗️ 2. Configuring the CA as Standalone Root

This section creates a **Standalone** Certification Authority (not integrated with Active Directory), with a 2048-bit RSA key, SHA256 hash, and 10-year validity.

```powershell
Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -KeyLength 2048 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 10 `
    -CACommonName "CA-Company-Root"
```

---

## 📤 3. Exporting the Root Certificate

This code block searches for the CA certificate in the **local cert store**, exports it as a `.cer` file, and notifies the outcome.

> 🔧 **Note:** Replace the `$caName` variable value with your actual CA name if different.

```powershell
# CA name (edit if needed)
$caName = "CA-Company-Root"

# Find the CA certificate (takes the first match)
$cert = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { $_.Subject -like "*$caName*" } | Select-Object -First 1

# Check if the certificate was found
if ($cert) {
    # Export the certificate
    Export-Certificate -Cert $cert -FilePath "C:\Certificates\CA-Company-Root.cer"
    Write-Host "✅ Certificate successfully exported to C:\Certificates\CA-Company-Root.cer"
} else {
    Write-Host "❌ Certificate not found for CA: $caName"
}
```

---

## 📦 4. Distributing the Certificate via GPO

Once the root certificate is exported, it must be distributed to network clients so they recognize it as **trusted**. This is done manually via Group Policy Objects (GPO):

To distribute the root certificate via GPO, follow these steps:
1. Copy the file 'C:\Certificates\CA-Company-Root.cer' to a domain controller.
2. Open the Group Policy Management Console (gpmc.msc).
3. Create or edit a GPO that targets the desired computers.
4. Go to: Computer Configuration > Policies > Windows Settings > Security Settings > Public Key Policies > Trusted Root Certification Authorities.
5. Right-click 'Import' and import the file C:\Certificates\CA-Company-Root.cer.

---

## 🧠 Considerations

- This setup is ideal for isolated environments, testing, or where an Active Directory-integrated CA is not required.
- Remember that certificates issued by a standalone CA are not automatically trusted by clients: **distribution via GPO is mandatory**.

