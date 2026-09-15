; 泡泡猫 DSH 桌面版 v2.1.2 安装脚本 (NSIS 3)
; 完全复刻 v1.6.6 的编译方式（File /r 直接复制目录）
Unicode true

!define SRCDIR "/root/软件应用工程区/dsh-desktop-pack"
!define APPNAME "泡泡猫 DSH"
!define APPVERSION "2.1.2"
!define UNINSTKEY "PaopaocatDSH"

!include "MUI2.nsh"
!include "nsDialogs.nsh"

Var hList

!define URL_ALIYUN "https://www.aliyun.com/benefit/scene/meoo?meoofrom=meoodashi&userCode=c8kxiiob"
!define URL_AIFADIAN "https://ifdian.net/a/paopaomao168"

Name "${APPNAME} 桌面版 ${APPVERSION}"
OutFile "${SRCDIR}/dist/PaopaocatDSH-Setup-v${APPVERSION}-x64.exe"
InstallDir "$LOCALAPPDATA\Programs\PaopaocatDSH"
InstallDirRegKey HKCU "Software\${UNINSTKEY}" "InstallDir"
RequestExecutionLevel user
SetCompressor /solid lzma
ShowInstDetails show
ShowUnInstDetails show

!define MUI_ABORTWARNING
!define MUI_UNICON "${SRCDIR}/paopaocat.ico"
!define MUI_FINISHPAGE_RUN "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\""
!define MUI_FINISHPAGE_RUN_TEXT "安装完成后立即启动 ${APPNAME}"

!insertmacro MUI_PAGE_WELCOME
Page custom PluginsShow
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

Function OpenUrl
  Exch $0
  ExecShell "open" $0
  Pop $0
FunctionEnd

Function OnAliyunClick
  Push "${URL_ALIYUN}"
  Call OpenUrl
FunctionEnd

Function OnAifadianClick
  Push "${URL_AIFADIAN}"
  Call OpenUrl
FunctionEnd

Function PluginsShow
  nsDialogs::Create 1018
  Pop $0
  ${NSD_CreateLabel} 0 0 100% 10u "📦 预装插件（17个），装好即用："
  Pop $0
  ${NSD_CreateListBox} 0 12u 100% 120u ""
  Pop $hList
  ${NSD_LB_AddString} $hList "🎬 泡泡猫影视工具 — AI 文生图/生视频"
  ${NSD_LB_AddString} $hList "🎨 泡泡猫玻璃主题 — 磨砂玻璃界面"
  ${NSD_LB_AddString} $hList "🎲 骰子大作战 — 吹牛等六种玩法"
  ${NSD_LB_AddString} $hList "📝 即时便签 — 彩色标签笔记"
  ${NSD_LB_AddString} $hList "🧠 长期记忆库 — AI 记住你的偏好"
  ${NSD_LB_AddString} $hList "👁️ 视觉路由 — 让文本模型看图"
  ${NSD_LB_AddString} $hList "🔁 模型回退 — 主模型失败自动切换"
  ${NSD_LB_AddString} $hList "🤖 领域专家团 — 17 个行业专家"
  ${NSD_LB_AddString} $hList "📊 GenUI — AI 渲染交互界面"
  ${NSD_LB_AddString} $hList "📚 Oh Story — 小说/短剧创作"
  ${NSD_LB_AddString} $hList "🧩 技能管理器 — 安全加载技能包"
  ${NSD_LB_AddString} $hList "⏰ 定时自动化 — 按计划执行任务"
  ${NSD_LB_AddString} $hList "💬 IM 接入 — 微信/QQ/钉钉/飞书"
  ${NSD_LB_AddString} $hList "📦 归档管理 — 会话归档与恢复"
  ${NSD_LB_AddString} $hList "🛒 插件市场 — 一键安装更多扩展"
  ${NSD_LB_AddString} $hList "📋 插件排行 — 透明榜单与推荐"
  ; 按钮
  ${NSD_CreateButton} 0 142u 150u 22u "☁️ 阿里云推荐配置"
  Pop $0
  ${NSD_OnClick} $0 OnAliyunClick
  ${NSD_CreateButton} 160u 142u 150u 22u "❤ 打赏作者"
  Pop $0
  ${NSD_OnClick} $0 OnAifadianClick
  ; 免责声明
  ${NSD_CreateLabel} 0 172u 100% 20u "⚠️ 除泡泡猫自研插件外，其余均收集整合自开源社区，仅供学习交流。联系：zmm168@163.com"
  Pop $0
  nsDialogs::Show
FunctionEnd

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}/node"
  File /r "${SRCDIR}/app"
  File /r "${SRCDIR}/git"
  File /r "${SRCDIR}/data-template"
  File /r "${SRCDIR}/launcher"
  File "${SRCDIR}/paopaocat.ico"
  File "${SRCDIR}/README.txt"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" \
    "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" \
    "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\"" \
    "$INSTDIR\paopaocat.ico" 0
  CreateShortCut "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk" \
    "$INSTDIR\Uninstall.exe" "" "$INSTDIR\paopaocat.ico" 0
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" \
    "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" \
    "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\"" \
    "$INSTDIR\paopaocat.ico" 0

  WriteRegStr HKCU "Software\${UNINSTKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "DisplayName" "${APPNAME} 桌面版"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "Publisher" "paopaocat"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "DisplayIcon" "$INSTDIR\paopaocat.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" \
    "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}"
  DeleteRegKey /ifempty HKCU "Software\${UNINSTKEY}"
  MessageBox MB_YESNO|MB_ICONQUESTION \
    "是否同时删除个人数据目录？$\n（含会话记录、API Key 等：%APPDATA%\PaopaocatDSH）" \
    IDNO done
  RMDir /r "$APPDATA\PaopaocatDSH"
done:
SectionEnd
