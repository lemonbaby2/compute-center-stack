param(
  [string]$Root = "D:\ComputeCenterStack\tools"
)

$ErrorActionPreference = "Stop"
$bin = Join-Path $Root "bin"
New-Item -ItemType Directory -Force -Path $Root, $bin | Out-Null

function Save-Url {
  param([string]$Url, [string]$OutFile)
  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Get-GitHubLatestTag {
  param([string]$Repo)
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "compute-center-stack-installer" }
  return $release.tag_name
}

function Expand-ZipToTemp {
  param([string]$ZipFile)
  $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("compute-tools-" + [System.Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $temp | Out-Null
  Expand-Archive -Path $ZipFile -DestinationPath $temp -Force
  return $temp
}

function Install-Kubectl {
  $version = (Invoke-WebRequest -Uri "https://dl.k8s.io/release/stable.txt" -UseBasicParsing).Content.Trim()
  $url = "https://dl.k8s.io/release/$version/bin/windows/amd64/kubectl.exe"
  Save-Url $url (Join-Path $bin "kubectl.exe")
}

function Install-Helm {
  $tag = Get-GitHubLatestTag "helm/helm"
  $version = $tag.TrimStart("v")
  $zip = Join-Path $Root "helm.zip"
  Save-Url "https://get.helm.sh/helm-v$version-windows-amd64.zip" $zip
  $temp = Expand-ZipToTemp $zip
  Copy-Item -Force (Join-Path $temp "windows-amd64\helm.exe") (Join-Path $bin "helm.exe")
  Remove-Item -Force $zip
  Remove-Item -Recurse -Force $temp
}

function Install-Kind {
  $tag = Get-GitHubLatestTag "kubernetes-sigs/kind"
  Save-Url "https://github.com/kubernetes-sigs/kind/releases/download/$tag/kind-windows-amd64" (Join-Path $bin "kind.exe")
}

function Install-K9s {
  $tag = Get-GitHubLatestTag "derailed/k9s"
  $zip = Join-Path $Root "k9s.zip"
  Save-Url "https://github.com/derailed/k9s/releases/download/$tag/k9s_Windows_amd64.zip" $zip
  $temp = Expand-ZipToTemp $zip
  Copy-Item -Force (Get-ChildItem -Path $temp -Recurse -Filter "k9s.exe" | Select-Object -First 1).FullName (Join-Path $bin "k9s.exe")
  Remove-Item -Force $zip
  Remove-Item -Recurse -Force $temp
}

function Install-Terraform {
  $checkpoint = Invoke-RestMethod -Uri "https://checkpoint-api.hashicorp.com/v1/check/terraform"
  $version = $checkpoint.current_version
  $zip = Join-Path $Root "terraform.zip"
  Save-Url "https://releases.hashicorp.com/terraform/$version/terraform_${version}_windows_amd64.zip" $zip
  $temp = Expand-ZipToTemp $zip
  Copy-Item -Force (Join-Path $temp "terraform.exe") (Join-Path $bin "terraform.exe")
  Remove-Item -Force $zip
  Remove-Item -Recurse -Force $temp
}

function Install-Jq {
  $tag = Get-GitHubLatestTag "jqlang/jq"
  Save-Url "https://github.com/jqlang/jq/releases/download/$tag/jq-windows-amd64.exe" (Join-Path $bin "jq.exe")
}

function Install-Yq {
  $tag = Get-GitHubLatestTag "mikefarah/yq"
  Save-Url "https://github.com/mikefarah/yq/releases/download/$tag/yq_windows_amd64.exe" (Join-Path $bin "yq.exe")
}

Install-Kubectl
Install-Helm
Install-Kind
Install-K9s
Install-Terraform
Install-Jq
Install-Yq

$env:Path = "$bin;$env:Path"

Write-Host ""
Write-Host "Installed tools:"
Get-ChildItem $bin -Filter *.exe | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

Write-Host ""
Write-Host "To add permanently to user PATH, run:"
Write-Host "[Environment]::SetEnvironmentVariable('Path', '$bin;' + [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')"

