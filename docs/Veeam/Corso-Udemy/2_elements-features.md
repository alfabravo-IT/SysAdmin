# Veeam Backup & Replication – Key Components

## 1. Backup Server

The **Veeam Backup Server** is the **central management component** of the Veeam Backup & Replication architecture. It orchestrates all backup, restore, replication, and recovery tasks.

### Main Roles
- Controls job scheduling and execution.
- Coordinates communication between components (proxies, repositories, etc.).
- Manages the configuration database and maintains metadata.
- Hosts the Veeam Backup & Replication console and services.

### Typical Deployment
- Runs on a Windows machine.
- Can be deployed on virtual or physical servers.

### Dependencies
- Requires Microsoft SQL Server (local or remote) for the configuration database.
- Uses TCP/IP networking to communicate with other Veeam components.

## 2. Backup Proxy

The **Backup Proxy** is responsible for **data processing during backup and replication** jobs. It handles the actual movement of data between the source and the target.

### Key Functions
- Retrieves VM data from production storage.
- Processes (compresses, deduplicates, encrypts) and sends data to the backup repository.
- Offloads the backup server to improve scalability.

### Transport Modes
- **Direct SAN Access**: Best performance; used with shared SAN storage.
- **Virtual Appliance (HotAdd)**: Used when the proxy is a VM.
- **Network Mode (NBD/NBDSSL)**: Uses the ESXi management network; slower.

### Scalability
- Multiple proxies can be deployed.
- Jobs are dynamically assigned to optimize resource use.

## 3. Backup Repository

The **Backup Repository** is the **storage location** where backup files, VM replicas, and metadata are stored.

### Supported Types
- Direct-attached storage (DAS)
- Network-attached storage (NAS: SMB/CIFS, NFS)
- Deduplication appliances (e.g., Data Domain, StoreOnce)
- Object storage (used with SOBR or for backup copies)

### Repository Files
- `.vbk` – Full backup
- `.vib` – Incremental backup
- `.vrb` – Reverse incremental (legacy mode)
- `.vbm` – Metadata

### Repository Roles
- Stores both primary and secondary backup data.
- Can be part of a **Scale-out Backup Repository (SOBR)** for better scalability and management.

## 4. Application-Aware Processing

**Application-Aware Image Processing (AAIP)** ensures **transactionally consistent backups** of enterprise applications inside VMs.

### Purpose
- Ensures **application-consistent** (not just crash-consistent) backups.
- Supports proper recovery of apps like SQL Server, Exchange, SharePoint, and Active Directory.

### How It Works
- Leverages **Microsoft Volume Shadow Copy Service (VSS)**.
- Injects a temporary process into the VM to coordinate with VSS.
- Optionally truncates logs (e.g., Exchange or SQL).

### Requirements
- Guest OS credentials with administrative rights.
- Network access or VMware Tools for guest interaction.

### Benefits
- Reliable application-level recovery.
- Enables granular restore (e.g., restore a mailbox, DB, AD object).