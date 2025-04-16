<#
.SYNOPSIS
    Script to locate and remove registry entries, services, and folders associated with "Azure Advanced Threat Protection Sensor".

.DESCRIPTION
    This script performs a series of tasks to uninstall and clean up residual files and registry entries related to
    "Azure Advanced Threat Protection Sensor". It stops and deletes associated services, removes registry entries
    based on GUIDs found in specific registry paths, deletes cache folders and installation folders associated with the GUID,
    and logs each action for auditing purposes.

.PARAMETER searchTerm
    The name of the application to search for in registry entries to identify related GUIDs.

.PARAMETER logFile
    Path to the log file where actions and results will be recorded.

.NOTES
    Version: 1.0
    Author: Sicheng Zhao
    Date: 10/28/2024

#>

# Function to write to a log file
function Write-Log {
    param (
        [string]$message,
        [string]$logFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Function to delete a service with notification if it doesn't exist, with double-check mechanism for deletion
function Delete-Service {
    param (
        [string]$serviceName,
        [string]$logFile
    )
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        try {
            # Stop the service
            sc.exe stop $serviceName
            Write-Host "'$serviceName' service is being stopped..."
            Write-Log "'$serviceName' service is being stopped." -logFile $logFile

            # Wait for service to stop completely
            $waitTime = 0
            while ((Get-Service -Name $serviceName -ErrorAction SilentlyContinue).Status -ne 'Stopped' -and $waitTime -lt 60) {
                Start-Sleep -Seconds 5
                $waitTime += 5
                Write-Host "Waiting for '$serviceName' to stop... $waitTime seconds elapsed."
                Write-Log "Waiting for '$serviceName' to stop... $waitTime seconds elapsed." -logFile $logFile
            }

            if ((Get-Service -Name $serviceName -ErrorAction SilentlyContinue).Status -eq 'Stopped') {
                Write-Host "'$serviceName' service has stopped."
                Write-Log "'$serviceName' service has stopped." -logFile $logFile
            } else {
                Write-Error "Failed to stop '$serviceName' within the timeout period."
                Write-Log "Failed to stop '$serviceName' within the timeout period." -logFile $logFile
                return
            }

            # Delete the service
            sc.exe delete $serviceName
            Write-Host "'$serviceName' service is being deleted..."
            Write-Log "'$serviceName' service is being deleted." -logFile $logFile

            # Double-check to ensure the service is deleted
            Start-Sleep -Seconds 5
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -eq $null) {
                Write-Host "'$serviceName' service has been successfully deleted."
                Write-Log "'$serviceName' service has been successfully deleted." -logFile $logFile
            } else {
                Write-Error "Service '$serviceName' could not be deleted."
                Write-Log "Service '$serviceName' could not be deleted." -logFile $logFile
            }
        } catch {
            Write-Error "Failed to stop or delete service '$serviceName': $_"
            Write-Log "Failed to stop or delete service '$serviceName': $_" -logFile $logFile
        }
    } else {
        Write-Warning "Service '$serviceName' does not exist."
        Write-Log "Service '$serviceName' does not exist." -logFile $logFile
    }
}

# Function to delete registry keys associated with a GUID
function Delete-RegistryKeys {
    param (
        [string]$guid,
        [string]$logFile
    )
    $registryPaths = @(
        "HKLM:\SOFTWARE\Classes\Installer\Products\",
        "HKLM:\SOFTWARE\Classes\Installer\Features\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Classes\Installer\Dependencies\"        
    )
    foreach ($path in $registryPaths) {
        $regKey = "$path$guid"
        if (Test-Path $regKey) {
            Write-Host "Deleting registry key: $regKey"
            Remove-Item -Path $regKey -Recurse -Force
            Write-Log "Deleted registry key: $regKey" -logFile $logFile
        } else {
            Write-Warning "Registry key not found: $regKey"
            Write-Log "Registry key not found: $regKey" -logFile $logFile
        }
    }
}

# Function to delete the folder in ProgramData\Package Cache
function Delete-CacheFolder {
    param (
        [string]$guid,
        [string]$logFile
    )
    $packageCacheFolder = "C:\ProgramData\Package Cache\$guid"
    if (Test-Path $packageCacheFolder) {
        Remove-Item -Path $packageCacheFolder -Recurse -Force
        Write-Host "Deleted folder: $packageCacheFolder"
        Write-Log "Deleted folder: $packageCacheFolder" -logFile $logFile
    } else {
        Write-Warning "Cache folder not found: $packageCacheFolder"
        Write-Log "Cache folder not found: $packageCacheFolder" -logFile $logFile
    }
}

# Function to delete the installation folder with notification if it doesn't exist
function Delete-InstallFolder {
    param (
        [string]$logFile
    )
    $installFolder = "C:\Program Files\Azure Advanced Threat Protection Sensor"
    if (Test-Path $installFolder) {
        Remove-Item -Path $installFolder -Recurse -Force
        Write-Host "Deleted installation folder: $installFolder"
        Write-Log "Deleted installation folder: $installFolder" -logFile $logFile
    } else {
        Write-Warning "Installation folder '$installFolder' does not exist."
        Write-Log "Installation folder '$installFolder' does not exist." -logFile $logFile
    }
}

# Function to find all GUIDs from the registry for "Azure Advanced Threat Protection Sensor"
function Find-GUIDs {
    param (
        [string]$searchTerm,
        [string]$logFile
    )
    $registryPaths = @(
        "HKLM:\SOFTWARE\Classes\Installer\Products\",
        "HKLM:\SOFTWARE\Classes\Installer\Features\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Classes\Installer\Dependencies\"
    )
    $guids = @()
    foreach ($path in $registryPaths) {
        $subKeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($key in $subKeys) {
            $keyPath = $path + $key.PSChildName
            $properties = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
            if ($properties.DisplayName -eq $searchTerm -or $properties.ProductName -eq $searchTerm) {
                $guids += $key.PSChildName
                Write-Log "Found GUID $($key.PSChildName) for '$searchTerm'" -logFile $logFile
            }
        }
    }
    # Return unique GUIDs
    return $guids | Select-Object -Unique
}

# Main script execution
$logFile = Join-Path $PSScriptRoot "MdiServiceDeletionLog.txt"
Write-Log "Script started." -logFile $logFile

$searchTerm = "Azure Advanced Threat Protection Sensor"

# Confirm service deletion
$confirmation = Read-Host "Do you want to stop and delete the services 'aatpsensor' and 'aatpsensorupdater'? (yes/no)"
if ($confirmation -eq 'no') {
    Write-Host "Deletion process aborted by the user."
    Write-Log "Deletion process aborted by the user." -logFile $logFile
    exit  # Exit the entire script if 'no' is selected
} elseif ($confirmation -eq 'yes') {
    Delete-Service -serviceName "aatpsensor" -logFile $logFile
    Delete-Service -serviceName "aatpsensorupdater" -logFile $logFile
} else {
    Write-Host "Invalid input. Aborting the deletion process."
    Write-Log "Invalid input. Aborting the deletion process." -logFile $logFile
    exit  # Exit the script if the input is invalid
}

# Find all GUIDs associated with the search term
$guids = Find-GUIDs -searchTerm $searchTerm -logFile $logFile
if ($guids.Count -gt 0) {
    Write-Host "Found GUIDs for '$searchTerm':"
    $guids | ForEach-Object { Write-Host $_ }

    # Confirm before deleting each GUID's related items
    $confirmation = Read-Host "Do you want to delete all registry keys and cache folders associated with the found GUIDs? (yes/no)"
    if ($confirmation -eq 'no') {
        Write-Host "Deletion process aborted by the user."
        Write-Log "Deletion process aborted by the user." -logFile $logFile
        exit  # Exit the entire script if 'no' is selected
    } elseif ($confirmation -eq 'yes') {
        foreach ($guid in $guids) {
            Delete-RegistryKeys -guid $guid -logFile $logFile
            Delete-CacheFolder -guid $guid -logFile $logFile
        }
    } else {
        Write-Host "Invalid input. Aborting the deletion process."
        Write-Log "Invalid input. Aborting the deletion process." -logFile $logFile
        exit  # Exit the script if the input is invalid
    }
} else {
    Write-Host "No GUIDs found for '$searchTerm'."
    Write-Log "No GUIDs found for '$searchTerm'." -logFile $logFile
}

# Confirm before deleting installation folder
$confirmation = Read-Host "Do you want to delete the installation folder for '$searchTerm'? (yes/no)"
if ($confirmation -eq 'no') {
    Write-Host "Deletion process aborted by the user."
    Write-Log "Deletion process aborted by the user." -logFile $logFile
    exit  # Exit the entire script if 'no' is selected
} elseif ($confirmation -eq 'yes') {
    Delete-InstallFolder -logFile $logFile
} else {
    Write-Host "Invalid input. Aborting the deletion process."
    Write-Log "Invalid input. Aborting the deletion process." -logFile $logFile
    exit  # Exit the script if the input is invalid
}

Write-Log "Script completed." -logFile $logFile
