; 泡泡猫 DSH 自定义皮肤（基于 gray + 泡泡猫 Logo）
!include "${NSISDIR}\Contrib\UltraModernUI\Skins\gray.nsh"

; 覆盖左侧位图
!undef UMUI_LEFTIMAGE_BMP
!define UMUI_LEFTIMAGE_BMP "${SRCDIR}/assets/Left.bmp"
