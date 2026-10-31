; 泡泡猫 DSH 桌面版 v3.0.0 安装脚本（基于 DSH 0.1.7-rc.2 重新打包）
; File /r 直接复制 node/app/git/launcher/data-template（中文文件名已转为英文）
Unicode true

; 编译前会被 rebuild.sh 用 sed 改写为干净的绝对构建目录
!define SRCDIR "."
!define APPNAME "泡泡猫 DSH"
!define APPVERSION "3.1.15"
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
SetCompressor zlib   ; solid lzma/bzip2 在本机 NSIS 3.08 上段错误，zlib 实测可用
CRCCheck on
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

Function .onInit
  ; $PLUGINSDIR：用于解出「关闭运行中程序」的临时脚本
  InitPluginsDir
FunctionEnd

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
  ${NSD_CreateLabel} 0 0 100% 10u "📦 预装插件（18个），装好即用："
  Pop $0
  ${NSD_CreateListBox} 0 12u 100% 140u ""
  Pop $hList
  ${NSD_LB_AddString} $hList "🎬 泡泡猫影视工具 — AI 文生图/生视频"
  ${NSD_LB_AddString} $hList "🎨 泡泡猫玻璃主题 — 磨砂玻璃界面"
  ${NSD_LB_AddString} $hList "🎲 骰子大作战 — 吹牛等六种玩法"
  ${NSD_LB_AddString} $hList "📝 即时便签 — 彩色标签笔记"
  ${NSD_LB_AddString} $hList "🧠 长期记忆库 — AI 记住你的偏好"
  ${NSD_LB_AddString} $hList "👁️ 视觉路由 — 让文本模型看图"
  ${NSD_LB_AddString} $hList "🤖 领域专家团 — 行业专家按需召唤"
  ${NSD_LB_AddString} $hList "📊 GenUI — AI 渲染交互界面"
  ${NSD_LB_AddString} $hList "📚 Oh Story — 小说/短剧创作"
  ${NSD_LB_AddString} $hList "🧩 技能管理器 — 安全加载技能包"
  ${NSD_LB_AddString} $hList "💬 IM 接入 — 微信/QQ/钉钉/飞书"
  ${NSD_LB_AddString} $hList "📦 归档管理 — 会话归档与恢复"
  ${NSD_LB_AddString} $hList "🛒 插件市场 — 一键安装更多扩展"
  ${NSD_LB_AddString} $hList "⏰ 定时自动化 — 按计划执行任务"
  ${NSD_LB_AddString} $hList "📋 插件排行 — 透明榜单与推荐"
  ${NSD_LB_AddString} $hList "🔁 LLM 容错 — 多模型自动回退"
  ${NSD_LB_AddString} $hList "🐱 泡泡猫新主题 — 温暖猫咪皮肤"
  ${NSD_CreateButton} 0 160u 150u 22u "☁️ 阿里云推荐配置"
  Pop $0
  ${NSD_OnClick} $0 OnAliyunClick
  ${NSD_CreateButton} 160u 160u 150u 22u "❤ 打赏作者"
  Pop $0
  ${NSD_OnClick} $0 OnAifadianClick
  ${NSD_CreateLabel} 0 190u 100% 20u "⚠️ 除泡泡猫自研插件外，其余均收集整合自开源社区，仅供学习交流。联系：zmm168@163.com"
  Pop $0
  nsDialogs::Show
FunctionEnd

Section "MainSection" SEC01
  ; ── 先关闭正在运行的旧版本 ──
  ; node.exe 是运行中的镜像、.node 是已加载的 DLL，Windows 会锁住它们；
  ; 不先关闭，下面的 File /r 会因无法覆盖而中断（表现为「安装包无法覆盖旧版本」）。
  close_running_app:
  SetOutPath "$PLUGINSDIR"
  File /oname=stop-running.ps1 "${SRCDIR}/launcher/stop-running.ps1"
  DetailPrint "检查是否有正在运行的 ${APPNAME}..."
  nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\stop-running.ps1" "$INSTDIR"'
  Pop $0
  StrCmp $0 "0" close_ok
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
      "检测到 ${APPNAME} 仍在运行，且无法自动关闭。$\n$\n请手动关闭它的窗口后点「重试」。$\n若不关闭，旧文件被占用，安装无法覆盖。$\n$\n提示：关闭启动器那个黑窗口，DSH 即停止。" \
      IDRETRY close_running_app
    Abort "安装已取消：请先关闭正在运行的 ${APPNAME}"
  close_ok:

  ; 覆盖安装：先清掉旧的程序目录。NSIS 与 robocopy 都只覆盖不删除，
  ; 上一次安装遗留的旧文件（例如插件里过时的嵌套依赖）会一直留着并污染新版本。
  ; 只删程序侧目录，用户数据在 %APPDATA% 里，不受影响。
  RMDir /r "$INSTDIR\app"
  RMDir /r "$INSTDIR\node"
  RMDir /r "$INSTDIR\git"
  RMDir /r "$INSTDIR\launcher"
  RMDir /r "$INSTDIR\data-template"

  SetOutPath "$INSTDIR"
  ; 逐目录递归复制（沿用 2.3.2 验证过的写法）。
  ; ⚠️ 打包前必须确认源目录内没有指向外部绝对路径的符号链接：
  ;    NSIS 会跟随链接递归到外部目录，导致 makensis 段错误。
  ;    本次已把 data-template 里 6 个 /dsh 绝对链接实体化成真实目录。
  File /r "${SRCDIR}/node"
  File /r "${SRCDIR}/app"
  File /r "${SRCDIR}/git"
  File /r "${SRCDIR}/launcher"
  File /r "${SRCDIR}/data-template"
  File "${SRCDIR}/paopaocat.ico"
  File "${SRCDIR}/README.txt"

  ; 版本标记：启动器据此判断是否需要把新版程序同步进数据目录（%APPDATA%）
  FileOpen $0 "$INSTDIR\launcher\version.txt" w
  FileWrite $0 "${APPVERSION}"
  FileClose $0

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
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayName" "${APPNAME} 桌面版"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "Publisher" "paopaocat"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "DisplayIcon" "$INSTDIR\paopaocat.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTKEY}" "NoRepair" 1
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
