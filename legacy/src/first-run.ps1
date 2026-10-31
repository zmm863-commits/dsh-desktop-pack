# 泡泡猫 DSH 首次配置向导 v2.0
# 支持 DeepSeek / MiMo / 任意 OpenAI 兼容 API Key
param([string]$EnvFile)
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.Text = '泡泡猫 DSH · 首次配置'
$form.Size = New-Object System.Drawing.Size(620, 340)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Topmost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 43)
$form.Add_Shown({ $form.Activate(); $form.BringToFront() })

# 标题
$title = New-Object System.Windows.Forms.Label
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.Size = New-Object System.Drawing.Size(575, 30)
$title.Text = '首次启动 - 配置 API Key'
$title.Font = New-Object System.Drawing.Font('Microsoft YaHei', 14, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(232, 201, 122)
$form.Controls.Add($title)

# 说明
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 52)
$label.Size = New-Object System.Drawing.Size(575, 50)
$label.Text = "请输入你的 API Key（仅保存在本机）。`n支持 DeepSeek、MiMo、LongCat 等 OpenAI 兼容接口。"
$label.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($label)

# Key 输入框
$text = New-Object System.Windows.Forms.TextBox
$text.Location = New-Object System.Drawing.Point(20, 108)
$text.Size = New-Object System.Drawing.Size(575, 28)
$text.Font = New-Object System.Drawing.Font('Consolas', 11)
$text.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55)
$text.ForeColor = [System.Drawing.Color]::White
$text.BorderStyle = 'FixedSingle'
$form.Controls.Add($text)

# 链接
$link = New-Object System.Windows.Forms.LinkLabel
$link.Location = New-Object System.Drawing.Point(20, 145)
$link.Size = New-Object System.Drawing.Size(575, 22)
$link.LinkColor = [System.Drawing.Color]::FromArgb(100, 160, 255)
$link.Text = '没有密钥？前往 platform.deepseek.com 免费注册 →'
$link.Add_LinkClicked({ Start-Process 'https://platform.deepseek.com/api_keys' })
$form.Controls.Add($link)

# 保存按钮
$ok = New-Object System.Windows.Forms.Button
$ok.Location = New-Object System.Drawing.Point(380, 240)
$ok.Size = New-Object System.Drawing.Size(100, 36)
$ok.Text = '保存'
$ok.BackColor = [System.Drawing.Color]::FromArgb(232, 201, 122)
$ok.ForeColor = [System.Drawing.Color]::FromArgb(30, 33, 43)
$ok.FlatStyle = 'Flat'
$ok.Font = New-Object System.Drawing.Font('Microsoft YaHei', 10, [System.Drawing.FontStyle]::Bold)
$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.Add($ok)

# 取消按钮
$cancel = New-Object System.Windows.Forms.Button
$cancel.Location = New-Object System.Drawing.Point(495, 240)
$cancel.Size = New-Object System.Drawing.Size(80, 36)
$cancel.Text = '跳过'
$cancel.BackColor = [System.Drawing.Color]::FromArgb(60, 64, 75)
$cancel.ForeColor = [System.Drawing.Color]::White
$cancel.FlatStyle = 'Flat'
$cancel.Font = New-Object System.Drawing.Font('Microsoft YaHei', 10)
$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancel
$form.Controls.Add($cancel)

$text.ActiveControl = $text
$result = $form.ShowDialog()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }

$key = $text.Text.Trim()
while ($true) {
  if ($key.Length -ge 10) { break }
  [System.Windows.Forms.MessageBox]::Show(
    "Key 太短了，请完整粘贴 API Key。",
    '泡泡猫 DSH', 'OK', 'Warning') | Out-Null
  $again = New-Object System.Windows.Forms.Form
  $again.Text = '泡泡猫 DSH · 重新输入'
  $again.Size = New-Object System.Drawing.Size(500, 180)
  $again.StartPosition = 'CenterScreen'
  $again.FormBorderStyle = 'FixedDialog'
  $again.MaximizeBox = $false
  $again.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 43)
  $t2 = New-Object System.Windows.Forms.TextBox
  $t2.Location = New-Object System.Drawing.Point(20, 30)
  $t2.Size = New-Object System.Drawing.Size(455, 28)
  $t2.Font = New-Object System.Drawing.Font('Consolas', 11)
  $t2.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55)
  $t2.ForeColor = [System.Drawing.Color]::White
  $again.Controls.Add($t2)
  $b = New-Object System.Windows.Forms.Button
  $b.Location = New-Object System.Drawing.Point(340, 90)
  $b.Size = New-Object System.Drawing.Size(135, 32)
  $b.Text = '保存并继续'
  $b.BackColor = [System.Drawing.Color]::FromArgb(232, 201, 122)
  $b.ForeColor = [System.Drawing.Color]::FromArgb(30, 33, 43)
  $b.FlatStyle = 'Flat'
  $b.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $again.AcceptButton = $b
  $again.Controls.Add($b)
  $again.ActiveControl = $t2
  if ($again.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }
  $key = $t2.Text.Trim()
}

[System.IO.File]::WriteAllText($EnvFile, "DEEPSEEK_API_KEY=$key`r`n")
exit 0
