# -*- coding: utf-8-with-signature-unix -*-

# Setup WSL2

#$ErrorActionPreference = 'Continue'

$distribution = "Ubuntu-20.04"
$downloadDir = "$HOME\Downloads"

cd $PSScriptRoot

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

### Install scoop ###

if ((Get-Command "scoop" -ErrorAction SilentlyContinue) -eq $null) {
    irm get.scoop.sh | iex
    $env:PATH="$env:PATH;$env:USERPROFILE\scoop\shims"
}

scoop bucket add extras
scoop install git
scoop update
scoop install gsudo
scoop install windows-terminal

### Install Windows features for WSL2 ###

Write-Host "管理者権限が必要な処理を行います。"
Write-Host ""
Write-Host "「このデバイスがアプリに変更を加えることを許可しますか」という確認には *「はい」を選択してください(２回表示されます)。"
Write-Host ""
Read-Host "Enter キーを押すと続行します"

sudo """$PSScriptRoot\setup-admin.ps1"""

### Update WSL Kernel ###

Write-Host ""
Write-Host "WSL カーネルのアップデートを行います。"
if ( ! (Test-Path "$downloadDir\wsl_update_x64.msi")) {
    Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "$downloadDir\wsl_update_x64.msi" -UseBasicParsing
}
msiexec /i "$downloadDir\wsl_update_x64.msi" /passive /norestart

### Install Ubuntu ###

Write-Host "$distribution をインストールしています。この操作には２０分程度時間がかかります。"
Write-Host "Ubuntu のインストールが完了すると自動的に Windows ターミナルが起動します。"
Write-Host "「Enter new UNIX username:」とユーザー名(半角のアルファベットで空白や記号が無いこと)を入力します。ご自身の Windows のユーザー名と同じで良いでしょう。"
Write-Host "「New password:」および「Retype new password:」と聞かれたらパスワードを２回入力してください。こちらも Windows のパスワードと同じでも良いでしょう。"
Read-Host "Enter キーを押すと続行します"

wsl.exe --install --distribution "$distribution"

### Set WSL version ###

wsl.exe --distribution "$distribution" --set-default-version 2

### Map WSL volume ###

Write-Host "U ドライブに $distribution を割り当てます。"
wsl --distribution "$distribution" true
cmd.exe /c "net use U: ""\\wsl.localhost\$distribution"""

### Create shortcuts ###

Write-Host "デスクトップに HOME ショートカットを作成します。"
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($desktopPath + "\HOME.lnk")
$Shortcut.TargetPath = "\\wsl.localhost\$distribution\home\$env:USERNAME"
$Shortcut.Save()

### Setup ubuntu ###

Write-Host "引き続き Ubuntu のセットアップを行います。"

wsl --distribution "$distribution" bash "`$(wslpath '$PSScriptRoot\setup.sh')"
