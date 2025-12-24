# qBittorrent Backup Script
# Backs up qBittorrent configuration, settings, and data to Downloads folder

# Create timestamped backup folder name
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFolderName = "qBittorrent_Backup_$timestamp"
$downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$backupPath = Join-Path -Path $downloadsPath -ChildPath $backupFolderName

# qBittorrent paths
$qbtAppDataPath = "$env:APPDATA\qBittorrent"
$qbtLocalAppDataPath = "$env:LOCALAPPDATA\qBittorrent"
$qbtProgramFiles = "${env:ProgramFiles}\qBittorrent"
$qbtProgramFilesX86 = "${env:ProgramFiles(x86)}\qBittorrent"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "qBittorrent Backup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Warning about running qBittorrent
if (Get-Process -Name qbittorrent -ErrorAction SilentlyContinue) {
    Write-Host "[WARNING] qBittorrent is currently running!" -ForegroundColor Yellow
    Write-Host "          For best results, close qBittorrent before backing up." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "Backup cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Create backup directory
try {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "[OK] Created backup folder: $backupPath" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create backup folder: $_" -ForegroundColor Red
    exit 1
}

# Function to backup a directory
function Backup-Directory {
    param(
        [string]$sourcePath,
        [string]$destinationPath,
        [string]$description
    )
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
            Write-Host "[OK] Backed up $description" -ForegroundColor Green
            
            # Get folder size
            $size = (Get-ChildItem -Path $destinationPath -Recurse | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host "     Size: $sizeMB MB" -ForegroundColor Gray
            
            # Count files
            $fileCount = (Get-ChildItem -Path $destinationPath -File -Recurse).Count
            Write-Host "     Files: $fileCount" -ForegroundColor Gray
            return $true
        } catch {
            Write-Host "[ERROR] Failed to backup $description : $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "[SKIP] $description not found at: $sourcePath" -ForegroundColor Yellow
        return $false
    }
}

# Function to backup specific files
function Backup-File {
    param(
        [string]$sourcePath,
        [string]$destinationFolder,
        [string]$description
    )
    
    if (Test-Path $sourcePath) {
        try {
            if (-not (Test-Path $destinationFolder)) {
                New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            }
            Copy-Item -Path $sourcePath -Destination $destinationFolder -Force
            Write-Host "[OK] Backed up $description" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[ERROR] Failed to backup $description : $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "[SKIP] $description not found" -ForegroundColor Yellow
        return $false
    }
}

# Backup counter
$backedUpItems = 0

# Backup AppData qBittorrent folder (main configuration)
Write-Host "`nBacking up configuration files..." -ForegroundColor Cyan
if (Backup-Directory -sourcePath $qbtAppDataPath -destinationPath "$backupPath\AppData_qBittorrent" -description "AppData configuration") {
    $backedUpItems++
    
    # List important files backed up
    Write-Host "`n     Important files included:" -ForegroundColor Gray
    $importantFiles = @(
        "qBittorrent.ini",
        "categories.json",
        "watched_folders.json",
        "rss\feeds.json",
        "rss\rules.json"
    )
    
    foreach ($file in $importantFiles) {
        $filePath = Join-Path -Path "$backupPath\AppData_qBittorrent" -ChildPath $file
        if (Test-Path $filePath) {
            Write-Host "     - $file" -ForegroundColor Gray
        }
    }
}

# Backup LocalAppData if it exists (BT_backup folder with resume data)
Write-Host "`nBacking up torrent resume data..." -ForegroundColor Cyan
if (Test-Path $qbtLocalAppDataPath) {
    if (Backup-Directory -sourcePath $qbtLocalAppDataPath -destinationPath "$backupPath\LocalAppData_qBittorrent" -description "LocalAppData (resume data)") {
        $backedUpItems++
        
        # Check for BT_backup folder
        $btBackupPath = Join-Path -Path "$backupPath\LocalAppData_qBittorrent" -ChildPath "BT_backup"
        if (Test-Path $btBackupPath) {
            $torrentCount = (Get-ChildItem -Path $btBackupPath -Filter "*.fastresume" -File).Count
            Write-Host "     Torrent resume files: $torrentCount" -ForegroundColor Gray
        }
    }
}

# Check for installation in Program Files
Write-Host "`nChecking for installation files..." -ForegroundColor Cyan
if (Test-Path $qbtProgramFiles) {
    $response = Read-Host "Found qBittorrent in Program Files. Backup installation folder? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        if (Backup-Directory -sourcePath $qbtProgramFiles -destinationPath "$backupPath\ProgramFiles_qBittorrent" -description "Program Files installation") {
            $backedUpItems++
        }
    }
} elseif (Test-Path $qbtProgramFilesX86) {
    $response = Read-Host "Found qBittorrent in Program Files (x86). Backup installation folder? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        if (Backup-Directory -sourcePath $qbtProgramFilesX86 -destinationPath "$backupPath\ProgramFiles_qBittorrent" -description "Program Files (x86) installation") {
            $backedUpItems++
        }
    }
}

# Create a backup info file
$infoFile = Join-Path -Path $backupPath -ChildPath "backup_info.txt"
$backupInfo = @"
qBittorrent Backup Information
==============================
Backup Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

Backed Up Locations:
"@

if (Test-Path "$backupPath\AppData_qBittorrent") {
    $backupInfo += "`n- AppData: $qbtAppDataPath"
}
if (Test-Path "$backupPath\LocalAppData_qBittorrent") {
    $backupInfo += "`n- LocalAppData: $qbtLocalAppDataPath"
}
if (Test-Path "$backupPath\ProgramFiles_qBittorrent") {
    if (Test-Path $qbtProgramFiles) {
        $backupInfo += "`n- Program Files: $qbtProgramFiles"
    } else {
        $backupInfo += "`n- Program Files: $qbtProgramFilesX86"
    }
}

# Check for qBittorrent.ini and extract some info
$configFile = "$qbtAppDataPath\qBittorrent.ini"
if (Test-Path $configFile) {
    $backupInfo += "`n`nConfiguration Details:"
    
    try {
        $configContent = Get-Content $configFile -Raw
        
        # Try to extract version
        if ($configContent -match 'CustomUIThemePath=(.+)') {
            $backupInfo += "`n- Custom Theme: Yes"
        }
        
        # Check for web UI
        if ($configContent -match 'WebUI\\Enabled=true') {
            $backupInfo += "`n- Web UI: Enabled"
        }
        
        # Check for RSS
        if ($configContent -match 'RSS\\AutoDownloader\\Enabled=true') {
            $backupInfo += "`n- RSS Auto-downloader: Enabled"
        }
    } catch {
        # Silently fail if we can't read the config
    }
}

$backupInfo | Out-File -FilePath $infoFile -Encoding UTF8

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Backup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Items backed up: $backedUpItems" -ForegroundColor Green

# Calculate total backup size
$totalSize = (Get-ChildItem -Path $backupPath -Recurse | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
$totalSizeGB = [math]::Round($totalSize / 1GB, 2)

if ($totalSizeGB -gt 1) {
    Write-Host "Total backup size: $totalSizeGB GB" -ForegroundColor Green
} else {
    Write-Host "Total backup size: $totalSizeMB MB" -ForegroundColor Green
}

Write-Host "Backup location: $backupPath" -ForegroundColor Green

# Option to compress
Write-Host "`n"
$compress = Read-Host "Would you like to compress the backup to a ZIP file? (y/n)"
if ($compress -eq 'y' -or $compress -eq 'Y') {
    $zipPath = "$backupPath.zip"
    Write-Host "Compressing backup..." -ForegroundColor Cyan
    Write-Host "(This may take a while for large backups)" -ForegroundColor Gray
    try {
        Compress-Archive -Path $backupPath -DestinationPath $zipPath -CompressionLevel Optimal -Force
        
        $zipSize = (Get-Item $zipPath).Length
        $zipSizeMB = [math]::Round($zipSize / 1MB, 2)
        $compressionRatio = [math]::Round(($totalSize - $zipSize) / $totalSize * 100, 1)
        
        Write-Host "[OK] Backup compressed to: $zipPath" -ForegroundColor Green
        Write-Host "     Compressed size: $zipSizeMB MB (saved $compressionRatio%)" -ForegroundColor Gray
        
        # Ask if user wants to delete the uncompressed folder
        $delete = Read-Host "Delete uncompressed backup folder? (y/n)"
        if ($delete -eq 'y' -or $delete -eq 'Y') {
            Remove-Item -Path $backupPath -Recurse -Force
            Write-Host "[OK] Uncompressed folder deleted" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Failed to compress: $_" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Backup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
