param([string]$EnvFile)
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.Text = '泡泡猫 DSH · 首次配置'
$form.Size = New-Object System.Drawing.Size(600, 280)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Topmost = $true
$form.Add_Shown({ $form.Activate(); $form.BringToFront() })

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 18)
$label.Size = New-Object System.Drawing.Size(545, 44)
$label.Text = "首次启动需要配置 DeepSeek API Key（仅保存在本机）。`n模型默认使用 deepseek-chat，可在设置中切换 deepseek-reasoner。"
$form.Controls.Add($label)

$text = New-Object System.Windows.Forms.TextBox
$text.Location = New-Object System.Drawing.Point(20, 72)
$text.Size = New-Object System.Drawing.Size(545, 26)
$form.Controls.Add($text)

$link = New-Object System.Windows.Forms.LinkLabel
$link.Location = New-Object System.Drawing.Point(20, 108)
$link.Size = New-Object System.Drawing.Size(545, 22)
$link.LinkColor = [System.Drawing.Color]::SteelBlue
$link.Text = '没有密钥？点击前往 platform.deepseek.com 免费注册并创建 API Key'
$link.Add_LinkClicked({ Start-Process 'https://platform.deepseek.com/api_keys' })
$form.Controls.Add($link)

$ok = New-Object System.Windows.Forms.Button
$ok.Location = New-Object System.Drawing.Point(390, 190)
$ok.Size = New-Object System.Drawing.Size(90, 32)
$ok.Text = '保存'
$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.Add($ok)

$cancel = New-Object System.Windows.Forms.Button
$cancel.Location = New-Object System.Drawing.Point(490, 190)
$cancel.Size = New-Object System.Drawing.Size(75, 32)
$cancel.Text = '取消'
$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancel
$form.Controls.Add($cancel)

$form.ActiveControl = $text
$result = $form.ShowDialog()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }

$key = $text.Text.Trim()
while ($true) {
  if ($key.Length -ge 20 -and $key.StartsWith('sk-')) { break }
  [System.Windows.Forms.MessageBox]::Show(
    "密钥格式不对：应以 sk- 开头且完整粘贴。`n可在 platform.deepseek.com 的 API Keys 页面复制。",
    '泡泡猫 DSH', 'OK', 'Warning') | Out-Null
  $again = New-Object System.Windows.Forms.Form
  $again.Text = '泡泡猫 DSH · 首次配置'
  $again.Size = New-Object System.Drawing.Size(600, 220)
  $again.StartPosition = 'CenterScreen'
  $again.FormBorderStyle = 'FixedDialog'
  $again.MaximizeBox = $false
  $t2 = New-Object System.Windows.Forms.TextBox
  $t2.Location = New-Object System.Drawing.Point(20, 40)
  $t2.Size = New-Object System.Drawing.Size(545, 26)
  $again.Controls.Add($t2)
  $b = New-Object System.Windows.Forms.Button
  $b.Location = New-Object System.Drawing.Point(430, 120)
  $b.Size = New-Object System.Drawing.Size(135, 32)
  $b.Text = '保存并继续'
  $b.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $again.AcceptButton = $b
  $again.Controls.Add($b)
  $again.ActiveControl = $t2
  if ($again.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }
  $key = $t2.Text.Trim()
}

[System.IO.File]::WriteAllText($EnvFile, "DEEPSEEK_API_KEY=$key`r`n")
exit 0
