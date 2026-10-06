#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  cachyos-synthwave84 — synth's full-system bootstrap
#  Fresh CachyOS install -> fully working grid in one script.
#  Theme: Synthwave '84 — deep purple, hot pink, 3270.
#
#  Usage (after gh auth login):
#    gh repo clone synthalorian/cachyos-synthwave84 && cd cachyos-synthwave84 && ./install.sh
#
#  Phases can be run individually: ./install.sh packages|configs|browsers|system|projects|ai|services|nvim
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

c_blood='\033[38;2;193;18;31m'        # BLOOD     #FF7EDB
c_parchment='\033[38;2;216;211;200m'  # PARCHMENT #FF7EDB
c_brass='\033[38;2;201;162;39m'       # BRASS     #F3E70F
c_reset='\033[0m'

say()  { echo -e "${c_pink}▸ ${c_reset}$1"; }
ok()   { echo -e "${c_cyan}  ✓ ${c_reset}$1"; }
warn() { echo -e "${c_yellow}  ! ${c_reset}$1"; }

# ─────────────────────────────────────────────────────────────────
phase_packages() {
  say "Phase 1: system packages (pacman)"
  sudo pacman -Syu --noconfirm
  # Install explicit packages from the manifest; skip any that no longer exist
  local failed=()
  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Si "$pkg" &>/dev/null; then
      sudo pacman -S --needed --noconfirm "$pkg" || failed+=("$pkg")
    else
      warn "not in repos (skipping): $pkg"
    fi
  done < "$REPO_DIR/manifest/packages.txt"
  ((${#failed[@]})) && warn "failed to install: ${failed[*]}" || true
  ok "packages done"
}

# ─────────────────────────────────────────────────────────────────
phase_configs() {
  say "Phase 2: user configs"

  mkdir -p "$HOME_DIR/.config" "$HOME_DIR/.local/share"

  # shell / terminal / fetch
  mkdir -p "$HOME_DIR/.config/fish" "$HOME_DIR/.config/alacritty" \
           "$HOME_DIR/.config/kitty" "$HOME_DIR/.config/fastfetch" \
           "$HOME_DIR/.config/ghostty"
  cp -r "$REPO_DIR/configs/fish/"*      "$HOME_DIR/.config/fish/"
  cp -r "$REPO_DIR/configs/alacritty/"* "$HOME_DIR/.config/alacritty/" 2>/dev/null || true
  cp -r "$REPO_DIR/configs/kitty/"*     "$HOME_DIR/.config/kitty/" 2>/dev/null || true
  cp -r "$REPO_DIR/configs/ghostty/"*   "$HOME_DIR/.config/ghostty/" 2>/dev/null || true

  # Vesktop (Vencord). QuickCSS is already enabled and hot-reloads; the named
  # theme lands in the themes folder. A running client keeps enabledThemes in
  # memory and will clobber a disk edit on the next settings write — Ctrl+R
  # after install if the sidebar is still stock.
  if [[ -d "$HOME_DIR/.config/vesktop" ]]; then
    mkdir -p "$HOME_DIR/.config/vesktop/themes" "$HOME_DIR/.config/vesktop/settings"
    cp "$REPO_DIR/configs/vesktop/Synthwave84.theme.css" \
      "$HOME_DIR/.config/vesktop/themes/Synthwave84.theme.css"
    cp "$REPO_DIR/configs/vesktop/Synthwave84.theme.css" \
      "$HOME_DIR/.config/vesktop/settings/quickCss.css"
    if [[ -f "$HOME_DIR/.config/vesktop/settings.json" ]]; then
      python3 - "$HOME_DIR/.config/vesktop/settings.json" <<'PY'
import json, sys
p = sys.argv[1]
with open(p) as f:
    d = json.load(f)
d["splashBackground"] = "rgb(13, 2, 33)"
d["splashColor"] = "rgb(255, 126, 219)"
with open(p, "w") as f:
    json.dump(d, f, indent=4)
    f.write("\n")
PY
    fi
    if [[ -f "$HOME_DIR/.config/vesktop/settings/settings.json" ]]; then
      python3 - "$HOME_DIR/.config/vesktop/settings/settings.json" <<'PY'
import json, sys
p = sys.argv[1]
with open(p) as f:
    d = json.load(f)
name = "Synthwave84.theme.css"
themes = d.get("enabledThemes") or []
if name not in themes:
    themes.append(name)
d["enabledThemes"] = themes
d["useQuickCss"] = True
with open(p, "w") as f:
    json.dump(d, f, indent=4)
    f.write("\n")
PY
    fi
    ok "vesktop synthwave '84 theme deployed"
  fi
  # fastfetch only parses ghostty/config (upstream path); Arch ghostty reads config.ghostty
  ln -sf config.ghostty "$HOME_DIR/.config/ghostty/config"
  cp -r "$REPO_DIR/configs/fastfetch/"* "$HOME_DIR/.config/fastfetch/"

  # nvim
  rm -rf "$HOME_DIR/.config/nvim"
  cp -r "$REPO_DIR/configs/nvim" "$HOME_DIR/.config/nvim"

  # KDE
  for f in kdeglobals kwinrc kwinrulesrc plasmarc kglobalshortcutsrc dolphinrc \
           kcminputrc plasma-org.kde.plasma.desktop-appletsrc kactivitymanagerdrc \
           kscreenlockerrc ksplashrc \
           baloofilerc gtkrc gtkrc-2.0; do
    [[ -f "$REPO_DIR/configs/kde/$f" ]] && cp "$REPO_DIR/configs/kde/$f" "$HOME_DIR/.config/$f"
  done
  mkdir -p "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/gtk-4.0"
  cp "$REPO_DIR/configs/kde/gtk-3.0-settings.ini" "$HOME_DIR/.config/gtk-3.0/settings.ini" 2>/dev/null || true
  cp "$REPO_DIR/configs/kde/gtk-4.0-settings.ini" "$HOME_DIR/.config/gtk-4.0/settings.ini" 2>/dev/null || true
  cp "$REPO_DIR/configs/kde/gtkrc-2.0-home" "$HOME_DIR/.gtkrc-2.0" 2>/dev/null || true
  mkdir -p "$HOME_DIR/.local/share/color-schemes" "$HOME_DIR/.local/share/plasma/desktoptheme" \
           "$HOME_DIR/.local/share/plasma/look-and-feel"
  cp -r "$REPO_DIR/configs/kde/color-schemes/"* "$HOME_DIR/.local/share/color-schemes/" 2>/dev/null || true
  cp -r "$REPO_DIR/configs/kde/desktoptheme/"*  "$HOME_DIR/.local/share/plasma/desktoptheme/" 2>/dev/null || true
  cp -r "$REPO_DIR/configs/kde/look-and-feel/"* "$HOME_DIR/.local/share/plasma/look-and-feel/" 2>/dev/null || true

  # xsettingsd (XSettings bridge for XWayland apps — cursor/icon theme source of truth)
  if [[ -f "$REPO_DIR/configs/xsettingsd/xsettingsd.conf" ]]; then
    mkdir -p "$HOME_DIR/.config/xsettingsd"
    cp "$REPO_DIR/configs/xsettingsd/xsettingsd.conf" "$HOME_DIR/.config/xsettingsd/xsettingsd.conf"
    pkill -x xsettingsd && sleep 0.3 || true
    (xsettingsd &>/dev/null &) || true
    ok "xsettingsd config deployed + restarted"
  fi

  # gsettings sync (GTK4/libadwaita read dconf, not settings.ini)
  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme 'Synthwave' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'candy-icons' 2>/dev/null || true
  fi

  # icons (Synthwave84-Icons forge + Vimix-cursors), fonts, plasmoids, wallpapers
  mkdir -p "$HOME_DIR/.local/share/icons" "$HOME_DIR/.local/share/fonts" \
           "$HOME_DIR/.local/share/plasma/plasmoids" "$HOME_DIR/Pictures"
  cp -r "$REPO_DIR/configs/icons/"*     "$HOME_DIR/.local/share/icons/"
  # candy-icons is the live theme and does not ship these names. Plasma
  # resolves tray IconName against the active theme only — a miss is a blank
  # icon, not an hicolor fallback. No index.theme here: a partial one would
  # replace the system theme definition.
  overlay="$HOME_DIR/.local/share/icons/candy-icons"
  mkdir -p "$overlay/apps/scalable" "$overlay/status/scalable"
  cp "$REPO_DIR/configs/icons/custom/apps/scalable/"cachy-update*.svg "$overlay/apps/scalable/" 2>/dev/null || true
  cp "$REPO_DIR/configs/icons/custom/status/scalable/"awake-mode-*.svg "$overlay/status/scalable/" 2>/dev/null || true
  # Forge the Synthwave84 icon theme (blood folders + steel/blood app set).
  # Requires papirus-icon-theme (pacman); nordzy-icon-theme (AUR) for the full
  # two-parent forge — the build script falls back to Papirus-only if absent.
  if [[ -d /usr/share/icons/Papirus-Dark ]]; then
    bash "$REPO_DIR/configs/icons/build-synthwave84-icons.sh" \
      && ok "Synthwave84-Icons forged" || warn "icon forge failed (non-fatal)"
    [[ -d /usr/share/icons/Nordzy-dark ]] || \
      warn "Nordzy-dark missing — Papirus fallback forged; install nordzy-icon-theme (AUR) + re-run configs/icons/build-synthwave84-icons.sh"
  else
    warn "Papirus-Dark missing — skipping Synthwave84 icon forge"
  fi
  cp -r "$REPO_DIR/configs/fonts/"*     "$HOME_DIR/.local/share/fonts/"
  cp -r "$REPO_DIR/configs/plasmoids/"* "$HOME_DIR/.local/share/plasma/plasmoids/"
  rm -rf "$HOME_DIR/Pictures/synthwave" "$HOME_DIR/Pictures/synthwave84-lock-login"
  cp -r "$REPO_DIR/wallpapers/synthwave" "$HOME_DIR/Pictures/synthwave"
  cp -r "$REPO_DIR/wallpapers/synthwave84-lock-login" "$HOME_DIR/Pictures/synthwave84-lock-login"
  rm -rf "$HOME_DIR/Pictures/synthwave84"
  cp -r "$REPO_DIR/wallpapers/synthwave84" "$HOME_DIR/Pictures/synthwave84"
  fc-cache -f &>/dev/null && ok "font cache rebuilt (3270 Nerd Font)"

  # git
  cp "$REPO_DIR/configs/git/gitconfig" "$HOME_DIR/.gitconfig"

  # user bin scripts (awake-mode never-sleep rig, etc.)
  if [[ -d "$REPO_DIR/configs/bin" ]]; then
    mkdir -p "$HOME_DIR/.local/bin"
    cp -r "$REPO_DIR/configs/bin/." "$HOME_DIR/.local/bin/"
    chmod +x "$HOME_DIR/.local/bin/"* 2>/dev/null || true
  fi
  # KDE autostart entries (rewrite __HOME__ placeholder to the real home)
  if [[ -d "$REPO_DIR/configs/kde/autostart" ]]; then
    mkdir -p "$HOME_DIR/.config/autostart"
    for f in "$REPO_DIR/configs/kde/autostart/"*.desktop; do
      [[ -f "$f" ]] || continue
      sed "s|__HOME__|$HOME_DIR|g" "$f" > "$HOME_DIR/.config/autostart/$(basename "$f")"
    done
  fi
  # awake-tray needs PySide6 (tray via QSystemTrayIcon)
  if [[ -f "$HOME_DIR/.local/bin/awake-tray" ]] && ! python3 -c "import PySide6" &>/dev/null; then
    warn "PySide6 missing — awake-tray won't start (pacman -S python-pyside6)"
  fi

  # default shell -> fish
  if [[ "$SHELL" != */fish ]]; then
    command -v fish &>/dev/null && chsh -s "$(command -v fish)" || warn "fish not installed yet — re-run after packages phase"
  fi

  ok "configs restored (log out/in for shell + KDE to fully apply)"
}

# ─────────────────────────────────────────────────────────────────
phase_browsers() {
  say "Phase 2a: browser themes (firefox + chromium) — SYNTHWAVE84"

  # ── Firefox: userChrome.css / userContent.css / user.js per profile ──
  if command -v firefox &>/dev/null; then
    local ff_root="$HOME_DIR/.mozilla/firefox"
    # Firefox 150+ headless runs on a throwaway profile and never creates the
    # install-default one — but a headless run with an explicit -profile DOES
    # materialize installs.ini + the install-default profile dir.
    if [[ ! -f "$ff_root/installs.ini" ]]; then
      say "no firefox profile yet — seeding one headlessly"
      mkdir -p "$ff_root"
      local seedprof="$ff_root/.seed-synthwave84"
      timeout 25 firefox --headless -profile "$seedprof" about:blank &>/dev/null || true
      rm -rf "$seedprof"
    fi
    # resolve targets: installs.ini Default first, then every *.default* dir
    local ff_profiles=()
    local ini_default
    ini_default=$(awk -F= '/^Default=/{print $2; exit}' "$ff_root/installs.ini" 2>/dev/null)
    [[ -n "$ini_default" && -d "$ff_root/$ini_default" ]] && ff_profiles+=("$ff_root/$ini_default")
    while IFS= read -r -d '' prof; do
      [[ " ${ff_profiles[*]:-} " == *" $prof "* ]] || ff_profiles+=("$prof")
    done < <(find "$ff_root" -maxdepth 1 -type d -name '*.default*' ! -name '.seed-*' -print0 2>/dev/null)
    if [[ ${#ff_profiles[@]} -eq 0 ]]; then
      warn "still no firefox profile — launch Firefox once, then re-run: ./install.sh browsers"
    else
      for prof in "${ff_profiles[@]}"; do
        mkdir -p "$prof/chrome"
        cp -r "$REPO_DIR/configs/browsers/firefox/chrome/"* "$prof/chrome/"
        if ! grep -q "synthwave84" "$prof/user.js" 2>/dev/null; then
          cat "$REPO_DIR/configs/browsers/firefox/user.js" >> "$prof/user.js"
        fi
        ok "firefox SYNTHWAVE84 deployed -> $(basename "$prof") (restart Firefox to apply)"
      done
    fi
  else
    warn "firefox not installed — skipping firefox theme"
  fi

  # ── Chromium: unpacked theme (developer-mode load) ──
  if command -v chromium &>/dev/null || command -v chromium-browser &>/dev/null; then
    mkdir -p "$HOME_DIR/.config/chromium-themes"
    rm -rf "$HOME_DIR/.config/chromium-themes/synthwave84"
    cp -r "$REPO_DIR/configs/browsers/chromium/synthwave84" "$HOME_DIR/.config/chromium-themes/synthwave84"
    ok "chromium theme staged at ~/.config/chromium-themes/synthwave84"
    warn "chromium blocks CLI theme installs — one-time manual step:"
    echo  "       chrome://extensions -> enable Developer mode -> Load unpacked -> ~/.config/chromium-themes/synthwave84"
  else
    warn "chromium not installed — skipping chromium theme"
  fi
}

# ─────────────────────────────────────────────────────────────────
phase_system() {
  say "Phase 2b: system boot/login (sudo) — plymouth + plasmalogin"

  # Plymouth boot splash (synthwave84)
  sudo cp -r "$REPO_DIR/configs/plymouth/synthwave84" /usr/share/plymouth/themes/
  sudo cp "$REPO_DIR/configs/system/plymouthd.conf" /etc/plymouth/plymouthd.conf
  sudo plymouth-set-default-theme synthwave84 2>/dev/null || true
  sudo mkinitcpio -P && ok "plymouth theme synthwave84 installed + initramfs rebuilt"

  # Plasma Login Manager: config + greeter font (3270 Nerd Font) + wallpaper
  sudo cp "$REPO_DIR/configs/system/plasmalogin.conf" /etc/plasmalogin.conf
  sudo install -d -m 700 -o plasmalogin -g plasmalogin /var/lib/plasmalogin/.config /var/lib/plasmalogin/wallpapers
  sudo install -m 644 -o plasmalogin -g plasmalogin \
    "$REPO_DIR/configs/system/plasmalogin-greeter-kdeglobals" /var/lib/plasmalogin/.config/kdeglobals
  sudo install -m 644 -o plasmalogin -g plasmalogin \
    "$REPO_DIR/wallpapers/synthwave84/lock-2560x1080.png" \
    /var/lib/plasmalogin/wallpapers/lock-2560x1080.png
  ok "plasmalogin: config + 3270 Nerd Font greeter + SYNTHWAVE84 login wallpaper"

  # Limine persistent kernel cmdline — rewrite root UUID from the LIVE fs.
  # Never deploy a hardcoded UUID (boot-loop, 2026-09-09).
  local root_uuid
  root_uuid=$(findmnt -no UUID /)
  if [[ -z "$root_uuid" ]]; then
    warn "could not detect live root UUID — SKIPPING /etc/default/limine"
  elif [[ -f "$REPO_DIR/configs/limine/default-limine" ]]; then
    sed "s/root=UUID=[^ \"]*/root=UUID=$root_uuid/" \
      "$REPO_DIR/configs/limine/default-limine" | sudo tee /etc/default/limine >/dev/null
    ok "limine default cmdline deployed (root=UUID=$root_uuid)"
  fi

  # Limine theme header ONLY. Never replace the entry block (boot panic 2026-09-24).
  if [[ -f "$REPO_DIR/configs/limine/limine.conf" && -f /boot/limine.conf ]]; then
    awk '/^\/\+/{exit} {print}' "$REPO_DIR/configs/limine/limine.conf" > /tmp/limine-theme.conf
    sudo awk '/^\/\+/{f=1} f{print}' /boot/limine.conf > /tmp/limine-entries.conf
    sudo bash -c 'cat /tmp/limine-theme.conf /tmp/limine-entries.conf > /boot/limine.conf.new && mv /boot/limine.conf.new /boot/limine.conf'
    sudo install -m 644 -o root -g root \
      "$REPO_DIR/configs/limine/limine-splash.png" /boot/limine-splash.png
    ok "limine theme header spliced + splash installed (entries preserved)"
  fi

  # 3270 system-wide so the plasmalogin user can resolve it
  if [[ -d "$REPO_DIR/configs/fonts/3270" ]]; then
    sudo mkdir -p /usr/local/share/fonts/3270
    sudo cp "$REPO_DIR/configs/fonts/3270/"* /usr/local/share/fonts/3270/
    sudo fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true
    ok "3270 installed system-wide for the greeter"
  fi

  # Kill 802.11 power save system-wide (rtw88 AER storm trigger)
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo cp "$REPO_DIR/configs/system/99-wifi-powersave-off.conf" /etc/NetworkManager/conf.d/99-wifi-powersave-off.conf
  ok "limine default cmdline + wifi powersave-off deployed"
}

# ─────────────────────────────────────────────────────────────────
phase_projects() {
  if [[ ! -f "$REPO_DIR/manifest/projects.tsv" ]]; then
    warn "no manifest/projects.tsv — project library is not part of the public theme repo"
    return 0
  fi
  say "Phase 3: project library (~/Projects)"
  mkdir -p "$HOME_DIR/Projects"/{active,archived,backburner,finished,forks,faith}

  clone_one() {
    local line="$1"
    local cat name remote
    IFS=$'\t' read -r cat name remote <<< "$line"
    local dest="$HOME/Projects/$cat/$name"
    if [[ -d "$dest/.git" ]]; then
      echo "  = exists: $cat/$name"
    else
      git clone --quiet "$remote" "$dest" && echo "  + cloned: $cat/$name" || echo "  ! FAILED: $cat/$name"
    fi
  }
  export -f clone_one

  grep -v '^$' "$REPO_DIR/manifest/projects.tsv" | xargs -d '\n' -P 8 -I {} bash -c 'clone_one "$@"' _ {}
  ok "projects cloned"
}

# ─────────────────────────────────────────────────────────────────
phase_ai() {
  say "Phase 4: AI stack (hermes, llama-swap, opencode)"

  # ── Hermes Agent ──
  if ! command -v hermes &>/dev/null; then
    say "installing Hermes Agent"
    curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
  fi
  mkdir -p "$HOME_DIR/.hermes"
  # Private Hermes state (SOUL.md, memories, cron) is NOT committed to the repo —
  # guard each copy so a public checkout can't hard-fail, and MERGE over live
  # state instead of replacing it.
  if [[ -f "$REPO_DIR/configs/hermes/SOUL.md" ]]; then
    cp "$REPO_DIR/configs/hermes/SOUL.md" "$HOME_DIR/.hermes/SOUL.md"
  else
    warn "configs/hermes/SOUL.md not in repo (private) — live SOUL.md untouched"
  fi
  if [[ -d "$REPO_DIR/configs/hermes/memories" ]]; then
    mkdir -p "$HOME_DIR/.hermes/memories"
    cp -r "$REPO_DIR/configs/hermes/memories/." "$HOME_DIR/.hermes/memories/"
  else
    warn "configs/hermes/memories not in repo (private) — live memories untouched"
  fi
  if [[ -d "$REPO_DIR/configs/hermes/scripts" ]]; then
    mkdir -p "$HOME_DIR/.hermes/scripts"
    cp -r "$REPO_DIR/configs/hermes/scripts/." "$HOME_DIR/.hermes/scripts/"
  fi
  # skills: merge repo over live (no hard-delete of live-only skills)
  if [[ -d "$REPO_DIR/skills" ]]; then
    mkdir -p "$HOME_DIR/.hermes/skills"
    cp -r "$REPO_DIR/skills/." "$HOME_DIR/.hermes/skills/"
  fi
  mkdir -p "$HOME_DIR/.hermes/cron"
  if [[ -f "$REPO_DIR/configs/hermes/cron-jobs.json" ]]; then
    cp "$REPO_DIR/configs/hermes/cron-jobs.json" "$HOME_DIR/.hermes/cron/jobs.json"
  fi
  # skins (themes) + pets (petdex sprites) — merge over live
  if [[ -d "$REPO_DIR/configs/hermes/skins" ]]; then
    mkdir -p "$HOME_DIR/.hermes/skins"
    cp -r "$REPO_DIR/configs/hermes/skins/." "$HOME_DIR/.hermes/skins/"
  fi
  if [[ -d "$REPO_DIR/configs/hermes/pets" ]]; then
    mkdir -p "$HOME_DIR/.hermes/pets"
    cp -r "$REPO_DIR/configs/hermes/pets/." "$HOME_DIR/.hermes/pets/"
  fi
  if [[ ! -f "$HOME_DIR/.hermes/config.yaml" ]]; then
    cp "$REPO_DIR/configs/hermes/config.example.yaml" "$HOME_DIR/.hermes/config.yaml"
    warn "hermes config.yaml seeded from template — fill in <FILL_IN> values (see docs/SECRETS.md)"
  else
    warn "existing hermes config.yaml kept — template at configs/hermes/config.example.yaml"
  fi

  # ── llama.cpp + llama-swap ──
  say "llama.cpp + llama-swap"
  mkdir -p "$HOME_DIR/llama.cpp" "$HOME_DIR/models" "$HOME_DIR/.config/llama-swap"
  cp "$REPO_DIR/configs/llama-swap/"*.yaml "$REPO_DIR/configs/llama-swap/"*.jinja "$HOME_DIR/.config/llama-swap/" 2>/dev/null || true

  if [[ ! -x "$HOME_DIR/.local/bin/llama-swap" ]]; then
    say "downloading llama-swap binary"
    local ls_url
    ls_url=$(curl -fsSL https://api.github.com/repos/mostlygeek/llama-swap/releases/latest \
      | grep -o '"browser_download_url": *"[^"]*linux_amd64\.tar\.gz"' | cut -d'"' -f4 | head -1)
    if [[ -n "$ls_url" ]]; then
      curl -fsSL "$ls_url" | tar -xz -C "$HOME_DIR/.local/bin" llama-swap
      chmod +x "$HOME_DIR/.local/bin/llama-swap"
    else
      warn "could not resolve llama-swap release — install manually from github.com/mostlygeek/llama-swap"
    fi
  fi

  if [[ ! -d "$HOME_DIR/llama.cpp/llama-b10092" ]]; then
    warn "llama.cpp b10092 binaries not present — see docs/MODELS.md for download instructions"
  fi
  warn "GGUF models NOT auto-downloaded (~19GB) — see docs/MODELS.md, then start llama-swap"

  # ── OpenCode ──
  mkdir -p "$HOME_DIR/.config/opencode"
  for f in opencode.jsonc tui.json oh-my-openagent.json AGENTS.md package.json; do
    [[ -f "$REPO_DIR/configs/opencode/$f" ]] && cp "$REPO_DIR/configs/opencode/$f" "$HOME_DIR/.config/opencode/$f"
  done
  if [[ -d "$REPO_DIR/configs/opencode/themes" ]]; then
    rm -rf "$HOME_DIR/.config/opencode/themes"
    cp -r "$REPO_DIR/configs/opencode/themes" "$HOME_DIR/.config/opencode/themes"
  fi

  ok "AI stack restored (secrets still needed — docs/SECRETS.md)"
}

# ─────────────────────────────────────────────────────────────────
phase_services() {
  say "Phase 5: systemd user services"
  mkdir -p "$HOME_DIR/.config/systemd/user"
  # copy contents (.service units AND .service.d drop-in dirs) — a bare *.service
  # glob silently drops the drop-ins
  cp -r "$REPO_DIR/configs/systemd/user/." "$HOME_DIR/.config/systemd/user/"
  systemctl --user daemon-reload
  for svc in llama-swap hermes-gateway openclaw-gateway; do
    [[ -f "$HOME_DIR/.config/systemd/user/$svc.service" ]] || continue
    systemctl --user enable "$svc" && ok "enabled $svc" || warn "could not enable $svc"
  done
  warn "services enabled but not started — start after secrets are filled in"
}

# ─────────────────────────────────────────────────────────────────
phase_nvim() {
  say "Phase 6: nvim plugins"
  if command -v nvim &>/dev/null; then
    nvim --headless "+Lazy! sync" +qa && ok "plugins synced"
  else
    warn "nvim not installed — skipping"
  fi
}

# ─────────────────────────────────────────────────────────────────
finale() {
  echo
  echo -e "${c_cyan}═══════════════════════════════════════════════════${c_reset}"
  echo -e "${c_pink}  Install finished. Remaining steps:${c_reset}"
  echo    "  1. Fill in secrets — see docs/SECRETS.md"
  echo    "  2. gh auth login (if not done)"
  echo    "  3. Log out/in (fish shell + KDE config)"
  echo -e "${c_cyan}═══════════════════════════════════════════════════${c_reset}"
}

# ─────────────────────────────────────────────────────────────────
expand_home_placeholders() {
  local f
  while IFS= read -r -d '' f; do
    grep -q '__HOME__' "$f" || continue
    sed -i "s|__HOME__|$HOME_DIR|g" "$f"
  done < <(find "$REPO_DIR" -type f -print0)
}

main() {
  expand_home_placeholders
  local phases=("${@:-all}")
  if [[ "${1:-all}" == "all" ]]; then
    phases=(packages configs browsers system nvim)
  fi
  for p in "${phases[@]}"; do
    "phase_$p"
  done
  finale
}

main "$@"
