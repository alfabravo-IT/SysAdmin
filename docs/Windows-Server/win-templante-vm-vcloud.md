# 🛠️ Creazione Template Windows Server su VMware vCloud Director

## 🧱 1. Creazione della VM di base

1. Crea una nuova VM da **vCloud Director GUI**:
   - Seleziona OS: Windows Server 2019/2022
   - Risorse: CPU, RAM, Disco (consigliato: disco singolo)
   - Rete: collegata, ma in DHCP o configurabile dopo il deploy

2. Installa **Windows Server** manualmente:
   - Completa l’installazione con nome temporaneo (es: `TEMPLATE-WS2022`)
   - Installa **VMware Tools**  
   - Applica aggiornamenti Windows
   - Installa strumenti comuni (PowerShell 7, Sysinternals, ecc.)

3. **Configura la VM per generalizzazione:**
   - Disattiva il firewall temporaneamente
   - Abilita RDP
   - Imposta il fuso orario corretto
   - **Disattiva la password di scadenza dell’amministratore**
   - Opzionale: installa BitLocker, ma **non abilitarlo**

---

## 🧽 2. Pulizia & Generalizzazione

1. Esegui pulizia:
   - `cleanmgr` o `Storage Sense`
   - Elimina i log di sistema e i file temporanei
   - Cancella vecchi aggiornamenti (`SoftwareDistribution\Download`)

2. Esegui **Sysprep**:

```powershell
cd C:\Windows\System32\Sysprep
.\sysprep.exe /oobe /generalize /shutdown
```

> La VM verrà spenta e pronta per il template.

---

## 📦 3. Creazione del Template nel Catalogo

1. Vai su **vCloud Director** con un ruolo con privilegi adeguati.
2. Vai su **vApp** > seleziona la VM spenta.
3. Clic su **Add to Catalog** (Aggiungi al Catalogo):
   - Nome es. `TEMPLATE-WS2022-BASE`
   - Seleziona Catalogo pubblico o privato (dipende da come è strutturato)
   - Opzionale: comprimi disco (per risparmiare spazio)

> Il sistema creerà un **vApp Template** nel Catalogo, da usare per future VM.

---

## 🧰 4. Deployment da vApp Template

Quando crei una nuova VM:

1. Vai su **Catalog > vApp Templates**
2. Seleziona il template e clicca su **Create vApp**
3. Imposta nome, rete, storage policy
4. Nella configurazione iniziale:
   - Inserisci hostname
   - Imposta IP (DHCP o statico)
   - Se necessario, collega script di provisioning (puoi usare guest customization)

---

## 🔧 5. Guest Customization (opzionale)

- Puoi attivare il **Guest OS Customization**:
   - Rename VM
   - Imposta password admin
   - Join al dominio (se configurato)
   - Setup automatico IP

Assicurati che nel template:
- I VMware Tools siano aggiornati
- Il sistema sia syspreppato

---

## 🏷️ Naming convention consigliata

```
TEMPLATE-WS2022-BASE
TEMPLATE-WS2019-HARDENED
TEMPLATE-WS2022-BITLOCKER
```

---

## 💡 Suggerimento

Per rendere più veloce il provisioning:
- Tieni una versione **snella** del template
- Lascia la personalizzazione avanzata post-deploy (via script o Ansible/PowerCLI)

