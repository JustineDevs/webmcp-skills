#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-desktop.sh probe
  scripts/webmcp-desktop.sh screenshot <path>
  scripts/webmcp-desktop.sh windows
  scripts/webmcp-desktop.sh open <application-or-url>
  scripts/webmcp-desktop.sh click <x> <y>
  scripts/webmcp-desktop.sh text <text>
  scripts/webmcp-desktop.sh key <key>

Supports macOS, Windows, and Linux desktop hosts through native tools. UI
automation may require Accessibility/Assistive Device permission on macOS,
desktop-session access on Linux, or an interactive Windows session.
EOF
}

die() {
  printf 'webmcp-desktop: %s\n' "$1" >&2
  exit 2
}

platform=${WEBMCP_DESKTOP_PLATFORM:-}
if [[ -z "$platform" ]]; then
  case "$(uname -s 2>/dev/null || true)" in
    Darwin) platform=macos ;;
    Linux) platform=linux ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) platform=windows ;;
    *) platform=unknown ;;
  esac
fi

json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

has() { command -v "$1" >/dev/null 2>&1; }

windows_command() {
  if has powershell.exe; then printf '%s\n' powershell.exe; return; fi
  if has pwsh; then printf '%s\n' pwsh; return; fi
  printf '%s\n' ''
}

probe() {
  case "$platform" in
    macos)
      printf '{"adapter":"desktop","platform":"macos","status":"ready","capabilities":{"screenshot":%s,"windows":true,"open":true,"text":true,"key":true,"click":%s}}\n' \
        "$(if has screencapture; then printf true; else printf false; fi)" \
        "$(if has cliclick; then printf true; else printf false; fi)"
      ;;
    linux)
      local screenshot=false click=false text=false
      if has gnome-screenshot || has scrot || has import; then screenshot=true; fi
      if has xdotool; then click=true; text=true; fi
      printf '{"adapter":"desktop","platform":"linux","status":"ready","capabilities":{"screenshot":%s,"windows":%s,"open":%s,"text":%s,"key":%s,"click":%s}}\n' \
        "$screenshot" "$(if has wmctrl || has xdotool; then printf true; else printf false; fi)" "$(if has xdg-open; then printf true; else printf false; fi)" "$text" "$text" "$click"
      ;;
    windows)
      local ps
      ps=$(windows_command)
      if [[ -z "$ps" ]]; then
        printf '{"adapter":"desktop","platform":"windows","status":"unavailable","reason":"PowerShell is unavailable"}\n'
      else
        printf '{"adapter":"desktop","platform":"windows","status":"ready","capabilities":{"screenshot":true,"windows":true,"open":true,"text":true,"key":true,"click":true}}\n'
      fi
      ;;
    *)
      printf '{"adapter":"desktop","platform":%s,"status":"unsupported","reason":"unsupported desktop host"}\n' "$(json_escape "$platform")"
      ;;
  esac
}

macos_osascript() {
  has osascript || die 'osascript is unavailable on macOS'
  osascript "$@"
}

macos_key() {
  local key=$1 code=''
  case "${key^^}" in
    ENTER|RETURN) code=36 ;;
    TAB) code=48 ;;
    SPACE) code=49 ;;
    BACKSPACE) code=51 ;;
    ESC|ESCAPE) code=53 ;;
    ARROW_LEFT|LEFT) code=123 ;;
    ARROW_RIGHT|RIGHT) code=124 ;;
    ARROW_DOWN|DOWN) code=125 ;;
    ARROW_UP|UP) code=126 ;;
    HOME) code=115 ;;
    END) code=119 ;;
    PAGE_UP) code=116 ;;
    PAGE_DOWN) code=121 ;;
  esac
  if [[ -n "$code" ]]; then
    macos_osascript -e "tell application \"System Events\" to key code $code"
  else
    local escaped
    escaped=$(escape_applescript "$key")
    macos_osascript -e "tell application \"System Events\" to keystroke \"$escaped\""
  fi
}

escape_applescript() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '%s' "$value"
}

windows_ps() {
  local ps
  ps=$(windows_command)
  [[ -n "$ps" ]] || die 'PowerShell is unavailable on Windows'
  "$ps" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$1"
}

case "${1:-}" in
  probe)
    [[ $# -eq 1 ]] || die 'probe takes no arguments'
    probe
    ;;
  screenshot)
    [[ $# -eq 2 ]] || die 'screenshot requires a path'
    output=$2; mkdir -p "$(dirname -- "$output")"
    case "$platform" in
      macos) has screencapture || die 'screencapture is unavailable'; screencapture -x "$output" ;;
      linux)
        if has gnome-screenshot; then gnome-screenshot -f "$output"; elif has scrot; then scrot "$output"; elif has import; then import -window root "$output"; else die 'install gnome-screenshot, scrot, or ImageMagick import'; fi
        ;;
      windows)
        windows_ps "Add-Type -AssemblyName System.Drawing; Add-Type -AssemblyName System.Windows.Forms; \$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; \$bmp=New-Object System.Drawing.Bitmap \$b.Width,\$b.Height; \$g=[System.Drawing.Graphics]::FromImage(\$bmp); \$g.CopyFromScreen(\$b.Location,[System.Drawing.Point]::Empty,\$b.Size); \$bmp.Save('$output'); \$g.Dispose(); \$bmp.Dispose()"
        ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    printf '{"adapter":"desktop","status":"completed","action":"screenshot","platform":%s,"path":%s}\n' "$(json_escape "$platform")" "$(json_escape "$output")"
    ;;
  windows)
    [[ $# -eq 1 ]] || die 'windows takes no arguments'
    case "$platform" in
      macos) macos_osascript -e 'tell application "System Events" to get name of every process whose background only is false' ;;
      linux) if has wmctrl; then wmctrl -l; elif has xdotool; then xdotool search --onlyvisible --name '.*' getwindowname %@; else die 'wmctrl or xdotool is required'; fi ;;
      windows) windows_ps 'Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object Id,ProcessName,MainWindowTitle | ConvertTo-Json -Compress' ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    ;;
  open)
    [[ $# -eq 2 ]] || die 'open requires an application or URL'
    case "$platform" in
      macos) open "$2" ;;
      linux) has xdg-open || die 'xdg-open is unavailable'; xdg-open "$2" >/dev/null 2>&1 ;;
      windows) target=$2; windows_ps "Start-Process -FilePath '$target'" ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    printf '{"adapter":"desktop","status":"completed","action":"open","platform":%s,"target":%s}\n' "$(json_escape "$platform")" "$(json_escape "$2")"
    ;;
  click)
    [[ $# -eq 3 ]] || die 'click requires x y'
    x=$2; y=$3; [[ "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ ]] || die 'coordinates must be non-negative integers'
    case "$platform" in
      macos) has cliclick || die 'cliclick is required for macOS coordinate clicks'; cliclick "c:$x,$y" ;;
      linux) has xdotool || die 'xdotool is required for Linux clicks'; xdotool mousemove "$x" "$y" click 1 ;;
      windows) windows_ps "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Mouse { [DllImport(\"user32.dll\")] public static extern bool SetCursorPos(int X,int Y); [DllImport(\"user32.dll\")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,uint e); }'; [Mouse]::SetCursorPos($x,$y); [Mouse]::mouse_event(0x0002,0,0,0,0); [Mouse]::mouse_event(0x0004,0,0,0,0)" ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    printf '{"adapter":"desktop","status":"completed","action":"click","platform":%s,"x":%s,"y":%s}\n' "$(json_escape "$platform")" "$x" "$y"
    ;;
  text)
    [[ $# -eq 2 ]] || die 'text requires text'
    value=$2
    case "$platform" in
      macos) escaped=$(escape_applescript "$value"); macos_osascript -e "tell application \"System Events\" to keystroke \"$escaped\"" ;;
      linux) has xdotool || die 'xdotool is required for Linux text input'; xdotool type --clearmodifiers --delay 1 -- "$value" ;;
      windows) escaped=${value//\`/\`\`}; escaped=${escaped//\"/\`\"}; windows_ps "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait(\"$escaped\")" ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    printf '{"adapter":"desktop","status":"completed","action":"text","platform":%s}\n' "$(json_escape "$platform")"
    ;;
  key)
    [[ $# -eq 2 ]] || die 'key requires a key name'
    key=$2
    case "$platform" in
      macos) macos_key "$key" ;;
      linux) has xdotool || die 'xdotool is required for Linux key input'; xdotool key --clearmodifiers "$key" ;;
      windows) windows_ps "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait(\"{$key}\")" ;;
      *) die "unsupported desktop platform: $platform" ;;
    esac
    printf '{"adapter":"desktop","status":"completed","action":"key","platform":%s,"key":%s}\n' "$(json_escape "$platform")" "$(json_escape "$key")"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
