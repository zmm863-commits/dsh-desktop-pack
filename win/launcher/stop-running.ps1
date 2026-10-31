# 泡泡猫 DSH — 安装前关闭正在运行的程序
# 由安装包在解包前调用：powershell -File stop-running.ps1 "<安装目录>"
# 目的：node.exe 与已加载的 .node 原生模块在运行时会锁定文件，
#       不先关闭则新版本无法覆盖旧文件。
param([string]$Root = "")

$ErrorActionPreference = 'SilentlyContinue'

if ([string]::IsNullOrWhiteSpace($Root)) { exit 0 }
$Root = $Root.TrimEnd('\') + '\'

function Get-Targets {
  Get-Process | Where-Object {
    $_.Path -and $_.Path.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)
  }
}

$targets = @(Get-Targets)
if ($targets.Count -eq 0) {
  Write-Host "  没有正在运行的进程"
  exit 0
}

foreach ($p in $targets) {
  Write-Host ("  发现 {0} (PID {1}) -> {2}" -f $p.ProcessName, $p.Id, $p.Path)
}

# 1) 先温和请求关闭
foreach ($p in $targets) {
  try { [void]$p.CloseMainWindow() } catch {}
}
Start-Sleep -Milliseconds 800

# 2) 未退出则强制结束
foreach ($p in @(Get-Targets)) {
  try { $p.Kill() } catch {}
}

# 3) 等待文件锁释放（最多 8 秒）
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Milliseconds 400
  if (@(Get-Targets).Count -eq 0) { break }
}

$left = @(Get-Targets)
if ($left.Count -gt 0) {
  Write-Host "  [警告] 以下进程未能关闭："
  foreach ($p in $left) {
    Write-Host ("    {0} (PID {1})" -f $p.ProcessName, $p.Id)
  }
  exit 1
}

Write-Host "  已全部关闭，文件锁已释放"
exit 0
