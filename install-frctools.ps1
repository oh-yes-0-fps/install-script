# Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/oh-yes-0-fps/install-script/main/install-frctools.ps1'))


# crash if not run as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    # https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1
    Write-Host "Installing winget..."
    #store it in documents
    $winget_installer = "$env:USERPROFILE\Documents\winget-install.ps1"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1 -OutFile $winget_installer
    #run it
    Start-Process -FilePath powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$winget_installer`"" -Wait
    #delete it
    Remove-Item $winget_installer
}


# install chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    # add chocolatey to path
    $env:Path += ";C:\ProgramData\chocolatey\bin"
} else {
    Write-Host "Chocolatey is already installed, Updating..."
    choco upgrade chocolatey -y
}

# refresh env variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

# intall/update the following with chocolatey:
$packages = @(
    "wpilib",
    "ni-frcgametools",
    "git",
    "python",
    "7zip",
    "adobereader",
    "meld",
    "revrobotics-hardwareclient",
    "frc-radioconfigurationutility",
    "etcher",
    "firefox",
    "autodesk-fusion360",
    "github-desktop",
    "winscp"
)

# make a function to check if package name is in choco list
function choco-list {
    param (
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    $list = choco list --exact $name
    if ($list -match $name) {
        return $true
    }
    return $false
}


foreach ($package in $packages) {
    # check if package is already installed
    if (choco-list($package)) {
        # Write-Host "$package is already installed, Updating..."
        choco upgrade $package -y
        continue
    }
    # Write-Host "Installing $package..."
    choco install $package -y
}

#enable wsl
Write-Host "Enabling WSL..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

#enable virtual machine platform
Write-Host "Enabling Virtual Machine Platform..."
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

#install wsl2 kernel
Write-Host "Installing WSL2 Kernel..."
Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile wsl_update_x64.msi
Start-Process -FilePath wsl_update_x64.msi -ArgumentList "/quiet", "/norestart" -Wait
Remove-Item wsl_update_x64.msi

#set wsl2 as default
Write-Host "Setting WSL2 as default..."
wsl --set-default-version 2

#install rust
# Write-Host "Installing Rust..."
# Invoke-WebRequest -Uri https://win.rustup.rs/x86_64 -OutFile rustup-init.exe
# Start-Process -FilePath rustup-init.exe -ArgumentList "/quiet", "/norestart", "-y" -Wait
# Remove-Item rustup-init.exe

$win_packages = @(
    "9NVV4PWDW27Z", #Tuner X
    "9NBLGGH4RSD8", #Arduino IDE
    "9NQBKB5DW909", #PathPlanner
    "9P9TQF7MRM4R", #WSL
    "9PDXGNCFSCZV"  #Ubuntu
)

foreach ($package in $win_packages) {
    winget install --disable-interactivity --accept-package-agreements --silent $package --source msstore
}

#check if wpilib did not install
if (-not (Test-Path "C:\Users\Public\wpilib")) {
    Write-Warning "WPILib did not install correctly, please run the installer again."
    Exit 1
}

$year = (Get-Date).Year

# add vscode to path
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    $env:Path += ";C:\Users\Public\wpilib\$year\vscode\bin"
}

# JAVA_HOME is not wpilib set it
#check if "wpilib" is in JAVA_HOME
if ($env:JAVA_HOME -notmatch "wpilib") {
    $env:JAVA_HOME = "C:\Users\Public\wpilib\$year\jdk"
    #add bin to path
    $env:Path += ";C:\Users\Public\wpilib\$year\jdk\bin"
}



# install vscode extensions
$extensions = @(
    "ms-python.python",
    "1YiB.rust-bundle",
    "tamasfe.even-better-toml",
    "usernamehw.errorlens",
    "mhutchie.git-graph",
    "oderwat.indent-rainbow",
    "donjayamanne.githistory",
    "waderyan.gitblame",
    "vscjava.vscode-java-pack",
    "richardwillis.vscode-gradle-extension-pack",
    "ZainChen.json",
    "GitHub.vscode-pull-request-github",
    "ms-vscode.hexeditor",
    "GitHub.vscode-pull-request-github",
    "ms-vscode-remote.vscode-remote-extensionpack",
    "vscode-icons-team.vscode-icons",
    "DmitryDorofeev.empty-indent"
)

foreach ($extension in $extensions) {
    # Write-Host "Installing $extension..."
    code --install-extension $extension
}

# set vscode settings by overwriting settings.json
# was having issues with multi line strings so I just did it this way
$vscode_settings = @"
    "terminal.integrated.defaultProfile.windows": "Git Bash",
    "vsicons.dontShowNewVersionMessage": true,
    "emptyIndent.removeIndent": false,
    "emptyIndent.highlightIndent": true,
    "git.autofetch": true,
    "redhat.telemetry.enabled": false,
    "files.autoSave": "afterDelay",
    "diffEditor.wordWrap": "off",
    "git.enableSmartCommit": true,
    "editor.inlineSuggest.enabled": true,
    "workbench.iconTheme": "vscode-icons",
    "editor.formatOnSave": true,
    "editor.renderWhitespace": "all"
"@

#add curly braces to settings
$vscode_settings = "{" + $vscode_settings + "}"

# delete vscode settings file if it exists
if (Test-Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json") {
    Remove-Item "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json"
}
# create vscode settings file
New-Item -Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json" -ItemType File
# write vscode settings to file
Set-Content -Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json" -Value $vscode_settings -Encoding ascii

