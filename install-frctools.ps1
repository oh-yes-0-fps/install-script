
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

$year = (Get-Date).Year

foreach ($extension in $extensions) {
    # Write-Host "Installing $extension..."
    C:\Users\Public\wpilib\$year\vscode\bin\code.cmd --install-extension $extension
}

$vscode_settings = '{"terminal.integrated.defaultProfile.windows": "Git Bash","vsicons.dontShowNewVersionMessage": true,"emptyIndent.removeIndent": false,"emptyIndent.highlightIndent": true,"git.autofetch": true,"redhat.telemetry.enabled": false,"files.autoSave": "afterDelay","diffEditor.wordWrap": "off","git.enableSmartCommit": true,"editor.inlineSuggest.enabled": true,"workbench.iconTheme": "vscode-icons","editor.formatOnSave": true,"editor.renderWhitespace": "all",}'

# set vscode settings by overwriting settings.json
$vscode_settings | Out-File -FilePath "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\settings.json" -Encoding ascii

