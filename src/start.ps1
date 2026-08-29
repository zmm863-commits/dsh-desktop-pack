# 泡泡猫 DSH 启动器 v1.2.0 · 全流程日志版
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$data = Join-Path $env:APPDATA 'PaopaocatDSH'
$log  = Join-Path $data 'launcher.log'
try { New-Item -ItemType Directory -Force -Path $data | Out-Null } catch {}
function Log([string]$m) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m"
  try { $line | Out-File -FilePath $log -Append -Encoding utf8 } catch {}
  Write-Host "    $m" -ForegroundColor DarkGray
}
function Fail([string]$m) {
  Log "FAIL: $m"
  try {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show("$m`n`n详细日志: $log", '泡泡猫 DSH 启动失败', 'OK', 'Error')
  } catch { Write-Host "启动失败: $m" }
  exit 1
}
Log '==================== launcher start ===================='
Log "root = $root"
Write-Host '泡泡猫 DSH 启动器' -ForegroundColor Cyan
Write-Host ("日志文件: {0}" -f $log) -ForegroundColor DarkGray

# ── 1/5 首次初始化数据目录 ──
Write-Host ''
Write-Host '[1/5] 检查数据目录...' -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $data 'profiles\web\node_modules'))) {
  Log 'step1 初始化数据目录'
  $tpl = Join-Path $root 'data-template'
  if (-not (Test-Path $tpl)) { Fail "缺少模板目录 $tpl，请重新安装" }
  robocopy $tpl $data /E /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { Fail "释放数据模板失败 robocopy 代码 $LASTEXITCODE" }
  Log 'step1 完成'
} else { Log 'step1 跳过（已初始化）' }

# ── 2/5 DeepSeek API Key ──
Write-Host '[2/5] 检查 API Key...' -ForegroundColor Cyan
$envFile = Join-Path $data '.env'
if (-not (Test-Path $envFile)) {
  Log 'step2 弹出密钥向导'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'first-run.ps1') -EnvFile $envFile
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $envFile)) { Fail '未输入 API Key，已取消' }
  Log 'step2 密钥已写入'
} else { Log 'step2 跳过（.env 已存在）' }

# ── 3/5 settings.yaml 预检、自愈与占位符替换 ──
Write-Host '[3/5] 校验配置文件...' -ForegroundColor Cyan
$settings = Join-Path $data 'settings.yaml'
$tplSettings = Join-Path $root 'data-template\settings.yaml'
function Test-Settings([string]$p) {
  $out = & "$root\node\node.exe" (Join-Path $PSScriptRoot 'check-settings.cjs') $root $p 2>&1
  $code = $LASTEXITCODE
  if ($code -ne 0) { Log "settings 预检失败($code): $out" }
  return ($code -eq 0)
}
if (-not (Test-Path $settings)) {
  Copy-Item -LiteralPath $tplSettings -Destination $settings
  Log 'step3 settings.yaml 缺失，已从模板创建'
} elseif (-not (Test-Settings $settings)) {
  Log 'step3 settings.yaml 损坏，用模板覆盖重建'
  Copy-Item -LiteralPath $tplSettings -Destination $settings -Force
}
if (-not (Test-Settings $settings)) { Fail 'settings.yaml 无法修复，请重新安装' }
Log 'step3 settings.yaml 校验通过'
if (Select-String -LiteralPath $settings -Pattern '__INSTALLDIR__' -Quiet) {
  (Get-Content -LiteralPath $settings -Raw -Encoding UTF8) -replace '__INSTALLDIR__', ($root -replace '\\', '/') |
    Set-Content -LiteralPath $settings -Encoding UTF8
  Log 'step3 占位符已替换为实际安装路径'
}

# ── 4/5 环境准备：内置 Node/Git + Edge 无头浏览器 ──
Write-Host '[4/5] 准备运行环境（内置 Node/Git、Edge 无头浏览器）...' -ForegroundColor Cyan
$env:PATH = "$root\git\cmd;$root\git\mingw64\bin;$root\node;$env:PATH"
$edgeCandidates = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)
foreach ($e in $edgeCandidates) {
  if (Test-Path $e) { $env:PUPPETEER_EXECUTABLE_PATH = $e; Log "step4 Edge 无头浏览器: $e"; break }
}

# ── 4.5 已在运行则只开网页 ──
$client = New-Object Net.Sockets.TcpClient
$busy = try { $client.Connect('127.0.0.1', 3080); $client.Connected } catch { $false } finally { $client.Close() }
if ($busy) {
  Log '端口 3080 已监听，视为已在运行'
  Start-Process 'http://127.0.0.1:3080'
  Log 'launcher exit(0)'
  exit 0
}

# ── 5/5 启动服务（前台，关窗即停）──
Write-Host '[5/5] 正在启动服务，浏览器将自动打开 http://127.0.0.1:3080 （关闭本窗口即停止 DSH）' -ForegroundColor Cyan
$env:DSH_HOME = $data
Log 'step5 启动 node web 服务'
& "$root\node\node.exe" "$root\app\lib\bin.js" web
$code = $LASTEXITCODE
Log "node 退出码 $code"
Write-Host ''
Write-Host "泡泡猫 DSH 已退出（退出码 $code）。日志: $log"
if ($code -ne 0 -and $code -ne $null) {
  try {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show("服务异常退出（代码 $code）。`n`n日志文件: $log", '泡泡猫 DSH', 'OK', 'Warning')
  } catch {}
}
Write-Host '按回车键关闭窗口...'
[void](Read-Host)
