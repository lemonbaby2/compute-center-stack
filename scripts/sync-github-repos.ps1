param(
  [string]$Csv = "D:\ComputeCenterStack\data\github-open-source-repos.csv",
  [string]$Target = "D:\ComputeCenterStack\github",
  [string[]]$Categories = @("gpu", "hpc", "monitoring", "orchestration"),
  [switch]$All,
  [switch]$IncludeHuge,
  [switch]$IncludeWindowsInvalid
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $Target | Out-Null

$hugeRepos = @(
  "kubernetes/kubernetes",
  "moby/moby",
  "grafana/grafana",
  "ceph/ceph",
  "elastic/elasticsearch",
  "pytorch/pytorch",
  "ray-project/ray",
  "NVIDIA/NeMo"
)

$windowsInvalidRepos = @(
  "schedmd/slurm",
  "lustre/lustre-release"
)

$repos = Import-Csv $Csv
if (-not $All) {
  $repos = $repos | Where-Object { $Categories -contains $_.category }
}
if (-not $IncludeHuge) {
  $repos = $repos | Where-Object { $hugeRepos -notcontains $_.repo }
}
if (-not $IncludeWindowsInvalid) {
  $repos = $repos | Where-Object { $windowsInvalidRepos -notcontains $_.repo }
}

if ($windowsInvalidRepos.Count -gt 0 -and -not $IncludeWindowsInvalid) {
  Write-Host "Skipping Windows-invalid source trees by default: $($windowsInvalidRepos -join ', ')"
  Write-Host "Clone them inside Ubuntu/WSL/Linux, or pass -IncludeWindowsInvalid if you know the checkout will work."
}

foreach ($repo in $repos) {
  $name = ($repo.repo -replace "/", "__")
  $path = Join-Path $Target $name
  if (Test-Path $path) {
    Write-Host "Updating $($repo.repo)"
    git -c http.proxy= -c https.proxy= -C $path pull --ff-only
  } else {
    Write-Host "Cloning $($repo.repo)"
    git -c http.proxy= -c https.proxy= clone --depth 1 $repo.clone_url $path
  }
  if ($LASTEXITCODE -ne 0) {
    throw "git operation failed for $($repo.repo)"
  }
}

Write-Host "Done. Repositories are under $Target"
