# 泡泡猫 DSH 启动器 v3.1.15
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

# 端口探测：3080 已被监听说明 DSH 正在运行
function Test-DshPort {
  $c = New-Object Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', 3080); return $c.Connected }
  catch { return $false }
  finally { $c.Close() }
}
Log '==================== launcher start ===================='
Log "root = $root"
Write-Host '泡泡猫 DSH 桌面版 v3.1.15（DSH 0.1.7-rc.2）' -ForegroundColor Cyan
Write-Host ("日志文件: {0}" -f $log) -ForegroundColor DarkGray

# ── 1/5 初始化 / 升级数据目录 ──
Write-Host ''
Write-Host '[1/5] 检查数据目录...' -ForegroundColor Cyan
$tpl = Join-Path $root 'data-template'
$verFile   = Join-Path $root 'launcher\version.txt'
$stampFile = Join-Path $data '.install-version'
$instVer = if (Test-Path $verFile) { (Get-Content -LiteralPath $verFile -Raw).Trim() } else { '' }
$recVer  = if (Test-Path $stampFile) { (Get-Content -LiteralPath $stampFile -Raw).Trim() } else { '' }
$isFresh = -not (Test-Path (Join-Path $data 'profiles\web\node_modules'))
# 依赖提升层（profiles\node_modules）是插件解析传递依赖所必需的。
# 判断依据是模板里的「层标记文件」而不是目录是否存在 —— 目录可能被 DSH 的
# 兜底机制或旧安装建出来，但内容残缺，仅靠存在性判断会误判为已就绪。
$layerDir  = Join-Path $data 'profiles\node_modules'
$layerMark = Join-Path $layerDir '.paopaocat-deps-layer'
$tplMark   = Join-Path $tpl 'profiles\node_modules\.paopaocat-deps-layer'
$layerOk = $false
if ((Test-Path $layerMark) -and (Test-Path $tplMark)) {
  try { $layerOk = ((Get-Content -LiteralPath $layerMark -Raw).Trim() -eq (Get-Content -LiteralPath $tplMark -Raw).Trim()) } catch { $layerOk = $false }
}
$needSync = (-not $layerOk)

if ($isFresh) {
  Log 'step1 初始化数据目录'
  if (-not (Test-Path $tpl)) { Fail "缺少模板目录 $tpl，请重新安装" }
  try {
    robocopy $tpl $data /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy 代码 $LASTEXITCODE" }
    if ($instVer) { Set-Content -LiteralPath $stampFile -Value $instVer -Encoding ascii }
    Log 'step1 完成'
  } catch { Fail "初始化数据目录失败: $_" }
} elseif (($instVer -and ($instVer -ne $recVer)) -or $needSync) {
  # 覆盖安装：把新版程序文件同步进数据目录；用户数据不会被触碰
  if (Test-DshPort) {
    Log 'step1 检测到 DSH 正在运行，本次不同步（下次启动生效）'
  } elseif (-not (Test-Path $tpl)) {
    Log 'step1 模板缺失，跳过同步'
  } else {
    if ($recVer) { Log "step1 版本 $recVer -> $instVer，同步程序文件" }
    elseif ($needSync -and $instVer -and ($instVer -eq $recVer)) { Log "step1 版本未变但依赖提升层缺失，补同步程序文件" }
    else { Log "step1 旧版本未记录，按 v$instVer 同步程序文件" }
    Write-Host "    正在更新到 v$instVer，保留你的设置、API Key 与会话..." -ForegroundColor Yellow
    try {
      # 同步前先清掉旧的程序侧目录：robocopy /E 只覆盖同名文件、不删旧文件，
      # 旧版残留会让两代程序混在一起（表现为「装的明明是新版，界面功能却还是旧版」）。
      # 只删程序侧目录，会话/设置/密钥（sessions、archives、.env、settings.yaml、.credentials.yaml）一概不动。
      foreach ($d in @('app','node','git','launcher','data-template')) {
        $old = Join-Path $data $d
        if (Test-Path $old) { Remove-Item -LiteralPath $old -Recurse -Force -ErrorAction SilentlyContinue }
      }
      # profile 的 node_modules 整层重建。robocopy 只覆盖不删除，上一次安装遗留的
      # 旧依赖（例如插件里过时/跨平台的嵌套包）会一直留着并污染解析，
      # 表现为插件 "failed to import"。这里连同提升层一起删干净再整层拷入。
      foreach ($d in @('profiles\web\node_modules','profiles\node_modules')) {
        $old = Join-Path $data $d
        if (Test-Path $old) { Remove-Item -LiteralPath $old -Recurse -Force -ErrorAction SilentlyContinue }
      }
      Log 'step1 已清理数据目录中的旧版程序文件'
      robocopy $tpl $data /E /XF .env settings.yaml .credentials.yaml launcher.log /XD sessions archives /NFL /NDL /NJH /NJS /NP | Out-Null
      if ($LASTEXITCODE -ge 8) { throw "robocopy 代码 $LASTEXITCODE" }
      Set-Content -LiteralPath $stampFile -Value $instVer -Encoding ascii
      Log 'step1 同步完成'
    } catch { Log "step1 同步失败（继续启动）: $_" }
  }
} else { Log 'step1 跳过（已是最新）' }

# ── 2/5 API Key ──
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
$settingsImported = Join-Path $data 'settings.yaml.imported'
$tplSettings = Join-Path $root 'data-template\settings.yaml'
if (-not (Test-Path $tplSettings)) { $tplSettings = Join-Path $data 'settings.yaml' }
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
  if (Test-Path $settingsImported) {
    # Mnemon 已把 settings.yaml 导入并改名为 settings.yaml.imported，配置已转存到
    # profiles\web\node_modules 之外的数据目录。这里**不能**再从模板重建：
    # 否则每次启动都会重演一次「旧设置导入」，而 mnemon 与 agency-agents 会抢同一把
    # 写锁（profiles\web\package.json.lock，默认只等 200ms），在 Windows 上以
    # "atomic-write: timed out waiting for the writer lock" 告警收场。
    Log 'step3 settings.yaml 已由 Mnemon 接管（settings.yaml.imported 存在），跳过重建'
  } elseif (Test-Path $tplSettings) { Copy-Item -LiteralPath $tplSettings -Destination $settings; Log 'step3 settings.yaml 缺失，已从模板创建' }
  else { Log 'step3 settings.yaml 缺失，跳过' }
} elseif (-not (Test-Settings $settings)) {
  Log 'step3 settings.yaml 损坏，用模板覆盖重建'
  if (Test-Path $tplSettings) { Copy-Item -LiteralPath $tplSettings -Destination $settings -Force }
}
Log 'step3 settings.yaml 校验通过'

# ── 4/5 环境准备 ──
Write-Host '[4/5] 准备运行环境（内置 Node/Git、Edge 无头浏览器）...' -ForegroundColor Cyan
$env:PATH = "$root\git\cmd;$root\git\mingw64\bin;$root\node;$env:PATH"
$browsers = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
)
foreach ($b in $browsers) {
  if (Test-Path $b) { $env:PUPPETEER_EXECUTABLE_PATH = $b; Log "step4 Edge 无头浏览器: $b"; break }
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

# ── 5/5 启动服务 ──
Write-Host '[5/5] 正在启动服务...' -ForegroundColor Cyan
Write-Host '浏览器将自动打开 http://127.0.0.1:3080' -ForegroundColor Green
Write-Host '（关闭本窗口即停止 DSH）' -ForegroundColor DarkGray
$env:DSH_HOME = $data
# 随包内置的 Mnemon CLI（长期记忆的存储后端）。用环境变量告知插件，
# 避免在模板里写死绝对路径；文件缺失时不设置，仍可回退到用户自装的 mnemon。
$mnemonCli = Join-Path $data 'mnemon-cli\node_modules\@mnemon-dev\mnemon\bin\mnemon.js'
if (Test-Path $mnemonCli) {
  $env:MNEMON_CLI_PATH = $mnemonCli
  Log "step5 Mnemon CLI: $mnemonCli"
}
Log 'step5 启动 DSH web 服务'
Write-Host ''
Write-Host '正在启动 DSH 服务，请稍等一会（首次启动约需 10~30 秒）...' -ForegroundColor Yellow
Write-Host '启动完成后浏览器会自动打开，请不要关闭本窗口。' -ForegroundColor Yellow
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
