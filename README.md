# qBittorrent Backup Script

A PowerShell utility that creates a complete, timestamped backup of your **qBittorrent configuration, settings, resume data, and optional installation files**.  
The script is designed for Windows systems and stores backups inside your **Downloads** folder for easy access and portability.

---

## ⭐ Features

- **Automatic timestamped backup folder**  
  Every run generates a uniquely named backup directory (e.g., `qBittorrent_Backup_2025-01-01_12-30-00`).

- **Backs up all major qBittorrent data locations**
  - `%AppData%\qBittorrent` (main configuration, categories, RSS, watched folders, etc.)
  - `%LocalAppData%\qBittorrent` (resume data, BT_backup)
  - `Program Files` or `Program Files (x86)` installation directory (optional)

- **Safety check for running qBittorrent**  
  Warns if qBittorrent is open and allows the user to cancel or continue.

- **Detailed backup reporting**
  - Folder sizes  
  - File counts  
  - Number of `.fastresume` torrent entries  
  - Detection of Web UI, RSS, and custom theme usage  
  - Auto‑generated `backup_info.txt` summary file  

- **Optional ZIP compression**  
  Compress the entire backup into a `.zip` file and optionally delete the uncompressed folder.

---

## 📁 What Gets Backed Up

### AppData Configuration
Includes:
- `qBittorrent.ini`
- `categories.json`
- `watched_folders.json`
- RSS configuration (`feeds.json`, `rules.json`)
- UI settings, preferences, and more

### LocalAppData Resume Data
Includes:
- `BT_backup` folder  
- `.fastresume` files for all active torrents

### Installation Directory (Optional)
If qBittorrent is installed in:
- `C:\Program Files\qBittorrent`  
- `C:\Program Files (x86)\qBittorrent`  
You can choose whether to include it in the backup.

---

## 📝 Generated Summary File

Each backup includes a `backup_info.txt` file containing:
- Backup date and time  
- Computer and user name  
- Paths included in the backup  
- Detected configuration features (Web UI, RSS Auto‑Downloader, custom themes)

---

## ▶️ How to Use

1. Save the script as `qBittorrentBackup.ps1`.
2. Right‑click → **Run with PowerShell**, or run from a PowerShell terminal.
3. Follow the prompts:
   - Close qBittorrent (recommended)
   - Choose whether to include installation files
   - Choose whether to compress the backup

The script handles the rest automatically.

---

## 📦 Example Output Structure

```
qBittorrent_Backup_2025-01-01_12-30-00/
│
├── AppData_qBittorrent/
├── LocalAppData_qBittorrent/
├── ProgramFiles_qBittorrent/   (optional)
└── backup_info.txt
```

---

## ✔️ Requirements

- Windows 10/11  
- PowerShell 5+  
- qBittorrent installed (standard or portable)
