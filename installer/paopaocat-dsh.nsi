; ═══════════════════════════════════════════════════════════
; 泡泡猫 DSH 桌面版 v2.1.0 安装程序
; 基于 DSH 0.1.5-rc.1 · 预装 16 个插件
; ═══════════════════════════════════════════════════════════
Unicode true

!define SRCDIR "/root/软件应用工程区/dsh-desktop-pack"
!define APPNAME "泡泡猫 DSH"
!define APPVERSION "2.1.0"
!define UNINSTKEY "PaopaocatDSH"

!include "MUI2.nsh"

VIProductVersion "2.1.0.0"
VIAddVersionKey "ProductName" "泡泡猫 DSH 桌面版"
VIAddVersionKey "CompanyName" "泡泡猫 (Paopaocat)"
VIAddVersionKey "FileDescription" "泡泡猫 DSH 桌面版安装程序"
VIAddVersionKey "FileVersion" "${APPVERSION}"
VIAddVersionKey "ProductVersion" "${APPVERSION}"
VIAddVersionKey "LegalCopyright" "Paopaocat"

Name "${APPNAME} 桌面版 ${APPVERSION}"
OutFile "${SRCDIR}/dist/PaopaocatDSH-Setup-v${APPVERSION}-x64.exe"
InstallDir "$LOCALAPPDATA\Programs\PaopaocatDSH"
InstallDirRegKey HKCU "Software\${UNINSTKEY}" "InstallDir"
RequestExecutionLevel user
SetCompressor /solid lzma
ShowInstDetails show
ShowUnInstDetails show

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING
!define MUI_ICON "${SRCDIR}/payload/paopaocat.ico"
!define MUI_UNICON "${SRCDIR}/payload/paopaocat.ico"
!define MUI_FINISHPAGE_RUN "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\""
!define MUI_FINISHPAGE_RUN_TEXT "安装完成后立即启动 ${APPNAME}"
!define MUI_FINISHPAGE_LINK "访问 GitHub 仓库"
!define MUI_FINISHPAGE_LINK_LOCATION "https://github.com/zmm863-commits/dsh-desktop-pack"

Var hList

!insertmacro MUI_PAGE_WELCOME
Page custom PluginsShow
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

Function PluginsShow
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 25u "📦 预装插件清单（17 个）"
  Pop $0

  ${NSD_CreateListBox} 0 28u 100% 170u ""
  Pop $hList

  ; === 泡泡猫自研 ===
  ${NSD_LB_AddString} $hList "--- 🐱 泡泡猫自研 ---"
  ${NSD_LB_AddString} $hList "🐱 泡泡猫玻璃主题 - 蓝白玻璃拟态 · 淡雅/蓝色双风格 · 内置流云壁纸"
  ${NSD_LB_AddString} $hList "🎬 泡泡猫的影视工具 - 文生图 / 图生图 / 多图合成 / 文生视频"
  ${NSD_LB_AddString} $hList "🎲 骰子大作战 - 吹牛等六种经典骰子游戏（山西晋城）"
  ; === AI 与智能 ===
  ${NSD_LB_AddString} $hList "--- 🧠 AI 与智能 ---"
  ${NSD_LB_AddString} $hList "🧠 长期记忆库（Mnemon）- AI 记住你的偏好与项目上下文"
  ${NSD_LB_AddString} $hList "👁️ 视觉路由（Vision Router）- 让纯文本模型也能看图"
  ${NSD_LB_AddString} $hList "🔁 模型回退（LLM Fallbacks）- 主模型失败自动切换备用"
  ${NSD_LB_AddString} $hList "🤖 领域专家团（Agency）- 17 个行业专家智能体"
  ; === 创作工具 ===
  ${NSD_LB_AddString} $hList "--- ✍️ 创作工具 ---"
  ${NSD_LB_AddString} $hList "📝 即时便签（Sticky Notes）- 彩色标签与定时提醒"
  ${NSD_LB_AddString} $hList "📊 GenUI - 让 AI 直接渲染交互式界面组件"
  ${NSD_LB_AddString} $hList "📚 Oh Story - 小说 / 短剧 / 互动游戏创作工具箱"
  ${NSD_LB_AddString} $hList "🧩 技能管理器（Skills Manager）- 安全加载技能包"
  ; === 系统与平台 ===
  ${NSD_LB_AddString} $hList "--- ⚙️ 系统与平台 ---"
  ${NSD_LB_AddString} $hList "⏰ 定时自动化（Automation）- 按计划在独立会话执行编码任务"
  ${NSD_LB_AddString} $hList "💬 IM 接入（IM Connect）- 微信/企微/钉钉/飞书/QQ/Telegram"
  ${NSD_LB_AddString} $hList "📦 归档管理（Archive Manager）- 会话归档与恢复"
  ${NSD_LB_AddString} $hList "🛒 插件市场（DSHMarket）- 一键安装更多扩展"
  ${NSD_LB_AddString} $hList "📋 插件排行（Recommend）- 透明榜单与推荐"

  ${NSD_CreateLabel} 0 200u 100% 30u "⚠️ 免责声明：除泡泡猫自研插件外，其余均收集整合自开源社区，仅供学习交流。联系：zmm168@163.com"
  Pop $0

  nsDialogs::Show
FunctionEnd

Section "MainSection"
  SetOutPath "$INSTDIR"
  SetOverwrite on

  DetailPrint "正在释放程序文件..."
  File "${SRCDIR}\payload-full.zip"

  DetailPrint "正在释放数据模板..."
  File "${SRCDIR}\payload\data-template.zip"

  DetailPrint "正在安装图标..."
  File "${SRCDIR}\payload\paopaocat.ico"

  DetailPrint "创建桌面快捷方式..."
  CreateShortCut "$DESKTOP\泡泡猫 DSH.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" '-NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\launcher\start.ps1"' "$INSTDIR\paopaocat.ico"

  CreateDirectory "$SMPROGRAMS\泡泡猫 DSH"
  CreateShortCut "$SMPROGRAMS\泡泡猫 DSH\泡泡猫 DSH.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" '-NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\launcher\start.ps1"' "$INSTDIR\paopaocat.ico"
  CreateShortCut "$SMPROGRAMS\泡泡猫 DSH\卸载.lnk" "$INSTDIR\uninstall.exe"

  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\${UNINSTKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayName" "${APPNAME} 桌面版"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayIcon" '"$INSTDIR\paopaocat.ico"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "Publisher" "泡泡猫 (Paopaocat)"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\泡泡猫 DSH.lnk"
  RMDir /r "$SMPROGRAMS\泡泡猫 DSH"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\${UNINSTKEY}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}"
SectionEnd
