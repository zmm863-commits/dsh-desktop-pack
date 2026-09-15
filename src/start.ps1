# 泡泡猫 DSH 启动器 v2.1.0 · 适配 DSH 0.1.5-rc.1
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
Write-Host '泡泡猫 DSH 桌面版 v2.1.0' -ForegroundColor Cyan
Write-Host ("日志文件: {0}" -f $log) -ForegroundColor DarkGray

# ── 0.5/5 首次释放 payload（zip 打包，makensis 规避中文路径段错误）──
$payloadZip = Join-Path $root 'payload-full.zip'
if ((Test-Path $payloadZip) -and -not (Test-Path (Join-Path $root 'node\node.exe'))) {
  Log 'step0.5 解压 payload-full.zip'
  Write-Host '[0/5] 首次释放程序文件...' -ForegroundColor Cyan
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($payloadZip)
    try {
      foreach ($entry in $archive.Entries) {
        $dest = Join-Path $root ($entry.FullName -replace '/', '\')
        if ($entry.FullName.EndsWith('/')) {
          if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
          continue
        }
        $dir = Split-Path -Parent $dest
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
      }
    } finally { $archive.Dispose() }
    Remove-Item -LiteralPath $payloadZip -Force
    Log 'step0.5 payload 解压完成'
  } catch {
    Log "step0.5 payload 解压失败: $_"
    Fail "程序文件释放失败，请重新安装"
  }
}

# ── 1/5 首次初始化数据目录 ──
Write-Host ''
Write-Host '[1/5] 检查数据目录...' -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $data 'profiles\web\node_modules'))) {
  Log 'step1 初始化数据目录'
  # 模板以 zip 形式随安装包分发：内含中文文件名（oh-story 技能资料），
  # 直接目录打包会让 makensis 段错误，故改为解压。
  $zip = Join-Path $root 'data-template.zip'
  if (-not (Test-Path $zip)) { Fail "缺少数据模板 $zip，请重新安装" }
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
    try {
      foreach ($entry in $archive.Entries) {
        $dest = Join-Path $data ($entry.FullName -replace '/', '\')
        if ($entry.FullName.EndsWith('/')) {
          if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
          continue
        }
        $dir = Split-Path -Parent $dest
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
      }
    } finally { $archive.Dispose() }
  } catch { Fail "解压数据模板失败: $($_.Exception.Message)" }
  Log 'step1 完成'
} else { Log 'step1 跳过（已初始化）' }

# ── 2/5 API Key（支持 DeepSeek / MiMo / 任意 OpenAI 兼容）──
Write-Host '[2/5] 检查 API Key...' -ForegroundColor Cyan
$envFile = Join-Path $data '.env'
if (-not (Test-Path $envFile)) {
  Log 'step2 弹出密钥向导'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'first-run.ps1') -EnvFile $envFile
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $envFile)) { Fail '未输入 API Key，已取消' }
  Log 'step2 密钥已写入'
} else { Log 'step2 跳过（.env 已存在）' }

# ── 3/5 settings.yaml 预检与自愈 ──
Write-Host '[3/5] 校验配置文件...' -ForegroundColor Cyan
$settings = Join-Path $data 'settings.yaml'
$tplSettings = Join-Path $root 'data-template\settings.yaml'
function Test-Settings([string]$p) {
  $checkScript = Join-Path $PSScriptRoot 'check-settings.cjs'
  if (-not (Test-Path $checkScript)) { return $true }
  $nodeExe = Join-Path $root 'node\node.exe'
  if (-not (Test-Path $nodeExe)) { return $true }
  $out = & $nodeExe $checkScript $root $p 2>&1
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
Log 'step3 settings.yaml 校验通过'

# ── 4/5 环境准备：内置 Node/Git + 浏览器检测 ──
Write-Host '[4/5] 准备运行环境...' -ForegroundColor Cyan
$env:PATH = "$root\git\cmd;$root\git\mingw64\bin;$root\node;$env:PATH"
# 检测 Edge/Chrome 用于 vision 等功能
$browsers = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
)
foreach ($b in $browsers) {
  if (Test-Path $b) { $env:PUPPETEER_EXECUTABLE_PATH = $b; Log "step4 浏览器: $b"; break }
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
Write-Host '[5/5] 正在启动服务...' -ForegroundColor Cyan
Write-Host '浏览器将自动打开 http://127.0.0.1:3080' -ForegroundColor Green
Write-Host '（关闭本窗口即停止 DSH）' -ForegroundColor DarkGray
$env:DSH_HOME = $data
Log 'step5 启动 DSH web 服务'
$nodeExe = Join-Path $root 'node\node.exe'
$dshBin = Join-Path $root 'app\lib\bin.js'
& $nodeExe $dshBin web
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
