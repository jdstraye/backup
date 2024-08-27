$exclusions = @(
    "C:\Apps\",
    "C:\Dell\",
    "C:\Drivers\",
    "C:\Intel\",
    "C:\PerfLogs\",
    "C:\ProgramData\",
    "C:\Program Files\",
    "C:\Program Files (x86)\",
    "C:\Windows\",
    "C:\Windows10Upgrade\",
    "C:\$Recycle.Bin\",
    "C:\Config.Msi\",
    "C:\OneDriveTemp\",
    "C:\Recovery\",
    "C:\System Volume Information\"
)

$userFolders = @(
    "Microsoft",
    "AppData",
    "Battle.net",
    "BlueStacks",
    "Application Data"
)

# Enumerate actual user directories under C:\Users
$users = Get-ChildItem -Path "C:\Users" | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name

# Add built-in user directories
$users += "Default"
$users += "All Users"
$users += "Public"
$users += "Administrator"
$users += "LocalService"
$users += "NetworkService"

# Add user-specific subfolders to exclusions
foreach ($user in $users) {
    foreach ($folder in $userFolders) {
        $exclusions += "C:\Users\$user\$folder\"
    }
}

# Output the exclusions
Write-Output $exclusions
