; 泡泡猫 DSH v1.6.6 - 纯 UMUI 效果（手动定义，避免 include 冲突）
Unicode true

!define SRCDIR "/root/软件/dsh-desktop-pack"
!define APPNAME "泡泡猫 DSH"
!define APPVERSION "1.6.6"
!define UNINSTKEY "PaopaocatDSH"

; === UMUI 核心 ===
!include "UMUI.nsh"
!include "nsDialogs.nsh"

; === 手动定义所有界面元素（不使用 gray.nsh）===
!define MUI_TEXTCOLOR FFFFFF
!define MUI_BGCOLOR 141c38
!define UMUI_TEXT_LIGHTCOLOR e8c97a
!define UMUI_HEADERTEXT_COLOR e8c97a
!define UMUI_BRANDINGTEXTFRONTCOLOR c5a468
!define UMUI_BRANDINGTEXTBACKCOLOR 141c38
!define UMUI_DISABLED_BUTTON_TEXT_COLOR 5a6480
!define UMUI_SELECTED_BUTTON_TEXT_COLOR e8c97a
!define UMUI_BUTTON_TEXT_COLOR 141c38
; 不定义 UMUI_LEFTIMAGE_BMP（空字符串会触发 UMUI 宏错误，省略=使用默认）
!define UMUI_HEADERBGIMAGE_BMP "${NSISDIR}\Contrib\UltraModernUI\Skins\gray\Header.bmp"
!define UMUI_BOTTOMIMAGE_BMP "${NSISDIR}\Contrib\UltraModernUI\Skins\gray\Bottom.bmp"
!define UMUI_BUTTONIMAGE_BMP "${NSISDIR}\Contrib\UltraModernUI\Skins\gray\Button.bmp"
!define UMUI_PAGEBGIMAGE_BMP "${NSISDIR}\Contrib\UltraModernUI\Skins\gray\PageBG.bmp"
!define UMUI_SCROLLBARIMAGE_BMP "${NSISDIR}\Contrib\UltraModernUI\Skins\gray\ScrollBar.bmp"

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

Name "${APPNAME} 桌面版 ${APPVERSION}"
OutFile "${SRCDIR}/dist/PaopaocatDSH-Setup-x64.exe"
InstallDir "$LOCALAPPDATA\Programs\PaopaocatDSH"
InstallDirRegKey HKCU "Software\${UNINSTKEY}" "InstallDir"
RequestExecutionLevel user
SetCompressor /solid lzma
ShowInstDetails show
ShowUnInstDetails show

!define MUI_ICON "${SRCDIR}/assets/paopaocat.ico"
!define MUI_UNICON "${SRCDIR}/assets/paopaocat.ico"

!define MUI_FINISHPAGE_RUN "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\""
!define MUI_FINISHPAGE_RUN_TEXT "安装完成后立即启动 ${APPNAME}"

; === 页面 ===
!insertmacro MUI_PAGE_WELCOME
Page custom PluginsShow
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

!define URL_ALIYUN "https://www.aliyun.com/bene\fit/scene/meoo?meoofrom=meoodashi&userCode=c8kxiiob"
!define URL_AIFADIAN "https://ifdian.net/a/paopaomao168"

Var hList

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
  ${NSD_CreateLabel} 0 0 100% 10u "内置以下插件，全部预装完毕，装好即用："
  Pop $0
  ${NSD_CreateListBox} 0 12u 100% 100u ""
  Pop $hList
  ${NSD_LB_AddString} $hList "🎲 dsh-dice-game —— 骰子大作战（吹牛等六种玩法）"
  ${NSD_LB_AddString} $hList "📎 paperclip —— 文件上传与附件"
  ${NSD_LB_AddString} $hList "🧠 dsh-mnemon —— 长期记忆库"
  ${NSD_LB_AddString} $hList "🤖 agency-agents —— 领域专家团（17 分部）"
  ${NSD_LB_AddString} $hList "⏰ dsh-automation —— 定时任务自动化"
  ${NSD_LB_AddString} $hList "💬 im-connect —— IM 接入（微信/QQ/飞书）"
  ${NSD_LB_AddString} $hList "🛒 dshmarket —— 插件市场"
  ${NSD_LB_AddString} $hList "🎨 maid-atelier —— 深海女仆工坊皮肤"
  ${NSD_CreateButton} 0 122u 150u 22u "☁️ 阿里云推荐配置"
  Pop $0
  ${NSD_OnClick} $0 OnAliyunClick
  ${NSD_CreateButton} 160u 122u 150u 22u "❤ 打赏作者"
  Pop $0
  ${NSD_OnClick} $0 OnAifadianClick
  ${NSD_CreateLabel} 0 152u 100% 8u "本软件插件除骰子大作战和文件上传为泡泡猫制作，"
  Pop $0
  ${NSD_CreateLabel} 0 164u 100% 8u "其余均收集整合自开源社区，仅供学习交流使用。"
  Pop $0
  ${NSD_CreateLabel} 0 176u 100% 8u "任何使用问题请联系：zmm168@163.com"
  Pop $0
  nsDialogs::Show
FunctionEnd

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}/payload/node"
  File /r "${SRCDIR}/payload/app"
  File /r "${SRCDIR}/payload/git"
  File /r "${SRCDIR}/payload/data-template"
  File /r "${SRCDIR}/payload/launcher"
  File "${SRCDIR}/payload/paopaocat.ico"
  File "${SRCDIR}/payload/README.txt"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\"" "$INSTDIR\paopaocat.ico" 0
  CreateShortCut "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\paopaocat.ico" 0
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\launcher\start.ps1$\"" "$INSTDIR\paopaocat.ico" 0
  WriteRegStr HKCU "Software\${UNINSTKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayName" "${APPNAME} 桌面版"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "Publisher" "paopaocat"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayIcon" "$INSTDIR\paopaocat.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "NoRepair" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "EstimatedSize" 700000
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}"
  DeleteRegKey /ifempty HKCU "Software\${UNINSTKEY}"
  MessageBox MB_YESNO|MB_ICONQUESTION "是否同时删除个人数据目录？$\n（含会话记录、API Key 等：%APPDATA%\PaopaocatDSH）" IDNO done
  RMDir /r "$APPDATA\PaopaocatDSH"
done:
SectionEnd
