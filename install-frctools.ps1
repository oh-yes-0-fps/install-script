
# crash if not run as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Exit 1
}

# install chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    # add chocolatey to path
    $env:Path += ";C:\ProgramData\chocolatey\bin"
} else {
    Write-Host "Chocolatey is already installed, Updating..."
    choco upgrade chocolatey -y
}

# intall the following with chocolatey (if not already installed):
$packages = @(
    "git",
    "python",
    "wpilib",
    "7zip",
    "adobereader",
    "meld",
    "ni-frcgametools",
    "revrobotics-hardwareclient",
    "frc-radioconfigurationutility",
    "etcher"
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
    # use choco list --local-only --exact to list exact package names
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



# add vscode to path
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    $year = (Get-Date).Year
    $env:Path += ";C:\Users\Public\wpilib\$year\vscode\bin"
}

# install vscode extensions
$extensions = @(
    "ms-python.python",
    "1YiB.rust-bundle",
    "bungcip.better-toml",
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
$vscode_settings = '{"terminal.integrated.defaultProfile.windows": "Git Bash","vsicons.dontShowNewVersionMessage": true,"emptyIndent.removeIndent": false,"emptyIndent.highlightIndent": true,"git.autofetch": true,"redhat.telemetry.enabled": false,"files.autoSave": "afterDelay","diffEditor.wordWrap": "off","git.enableSmartCommit": true,"editor.inlineSuggest.enabled": true,"workbench.iconTheme": "vscode-icons","editor.formatOnSave": true,"editor.renderWhitespace": "all",}'
# delete vscode settings file if it exists
if (Test-Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json") {
    Remove-Item "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json"
}
# create vscode settings file
New-Item -Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json" -ItemType File
# write vscode settings to file
Set-Content -Path "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json" -Value $vscode_settings -Encoding ascii

