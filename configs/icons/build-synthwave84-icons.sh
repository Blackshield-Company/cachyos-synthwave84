#!/usr/bin/env bash
# build-synthwave84-icons.sh — Forge the Synthwave84 icon theme.
#
# Builds ~/.local/share/icons/Synthwave84-Icons from two installed parents:
#   - Papirus-Dark  (blood-red folders + blood system accent icons)
#   - Nordzy-dark   (full app/mimetype set, reforged steel+blood palette)
#
# Idempotent: wipes and rebuilds the theme dir every run.
# Deps: papirus-icon-theme (pacman), nordzy-icon-theme (AUR), python3.
# After Papirus or Nordzy updates, re-run to pick up new icons.

set -euo pipefail

PAPIRUS=/usr/share/icons/Papirus-Dark
NORDZY=/usr/share/icons/Nordzy-dark
DST="$HOME/.local/share/icons/Synthwave84-Icons"

if [[ ! -d "$PAPIRUS" ]]; then
  echo "MISSING: $PAPIRUS — install papirus-icon-theme first" >&2
  exit 1
fi

# Fallback mode: Nordzy-dark missing -> reforge Papirus for the full set too.
# Install nordzy-icon-theme (AUR) and re-run for the full two-parent forge.
export SYNTHWAVE84_FALLBACK=0
if [[ ! -d "$NORDZY" ]]; then
  echo "FALLBACK: $NORDZY missing — forging Papirus-only Synthwave84-Icons" >&2
  echo "          install nordzy-icon-theme (AUR) and re-run for the full forge" >&2
  NORDZY="$PAPIRUS"
  export SYNTHWAVE84_FALLBACK=1
fi

echo "Forging Synthwave84-Icons -> $DST"
rm -rf "$DST"
mkdir -p "$DST"

python3 - "$PAPIRUS" "$NORDZY" "$DST" <<'PYEOF'
import os, re, sys

PAPIRUS, NORDZY, DST = sys.argv[1], sys.argv[2], sys.argv[3]
FALLBACK = os.environ.get("SYNTHWAVE84_FALLBACK") == "1"

# ---------------------------------------------------------------- palette map
HEXMAP = {
    # Papirus folder reds -> canon blood family
    "#e25252": "#FF7EDB", "#bf4b4b": "#FF00FF", "#4f1d1d": "#4B0080",
    # nord frost blues/cyans -> steel greys
    "#8fbcbb": "#B084EB", "#88c0d0": "#B084EB", "#81a1c1": "#614D85", "#5e81ac": "#4B0080",
    # nord aurora reds -> canon blood family
    "#bf616a": "#FF7EDB", "#b54a55": "#FF00FF",
    # warm aurora -> rusted blood / bone / ash / gunmetal
    "#d08770": "#FE4450", "#ebcb8b": "#FF7EDB", "#a3be8c": "#82887B", "#b48ead": "#736F78",
    # Papirus system accent blues/teals/greens -> blood
    "#127bdc": "#FF7EDB", "#1f6394": "#8F00FF", "#008374": "#FF7EDB",
    "#34abf3": "#FF7EDB", "#00e441": "#FF7EDB", "#5294e2": "#FF7EDB", "#3daee9": "#FF7EDB",
    # nord variant tints
    "#97b67c": "#82887B", "#ad85a5": "#736F78", "#eac57b": "#FF7EDB",
    # nord pastel highlight family -> bone/steel tints
    "#eac7ae": "#FF7EDB", "#e7ddaf": "#FF7EDB", "#caefb9": "#C4C9BC",
    "#b1e3da": "#BFC6C2", "#a5c5ee": "#B9BEC6",
}
def remap(content):
    return re.sub(r"#[0-9a-fA-F]{6}\b",
                  lambda m: HEXMAP.get(m.group(0).lower(), m.group(0)), content)

# --------------------------------------- layer 1: Papirus blood folders
folders = 0
for d in sorted(os.listdir(PAPIRUS)):
    if not re.fullmatch(r"\d+x\d+(@2x)?", d):
        continue
    places = os.path.join(PAPIRUS, d, "places")
    if not os.path.isdir(places):
        continue
    outdir = os.path.join(DST, d, "places")
    for f in sorted(os.listdir(places)):
        full = os.path.join(places, f)
        if os.path.islink(full) or not f.endswith(".svg"):
            continue
        if not (f.startswith("folder-red") or f.startswith("user-red")):
            continue
        canonical = f.replace("-red", "", 1)
        os.makedirs(outdir, exist_ok=True)
        with open(full) as fh:
            content = fh.read()
        with open(os.path.join(outdir, canonical), "w") as fh:
            fh.write(remap(content))
        folders += 1

# --------------------------- layer 1b: places aliases (inode-directory etc.)
aliases = 0
for d in sorted(os.listdir(PAPIRUS)):
    if not re.fullmatch(r"\d+x\d+(@2x)?", d):
        continue
    places = os.path.join(PAPIRUS, d, "places")
    if not os.path.isdir(places):
        continue
    outdir = os.path.join(DST, d, "places")
    for f in sorted(os.listdir(places)):
        full = os.path.join(places, f)
        if not os.path.islink(full) or not f.endswith(".svg"):
            continue
        real = os.path.basename(os.path.realpath(full))
        if not (real.startswith("folder-red") or real.startswith("user-red")):
            continue
        canonical = real.replace("-red", "", 1)
        if f == canonical or not os.path.exists(os.path.join(outdir, canonical)):
            continue
        link = os.path.join(outdir, f)
        if os.path.lexists(link):
            os.remove(link)
        os.symlink(canonical, link)
        aliases += 1

# ----------------------------- layer 2: Papirus blood system accent icons
TARGETS = {"org.kde.dolphin.svg", "system-file-manager.svg", "utilities-tweak-tool.svg",
           "plasmadiscover.svg", "utilities-system-monitor.svg"}
sysicons = 0
for d in sorted(os.listdir(PAPIRUS)):
    if not re.fullmatch(r"\d+x\d+(@2x)?", d):
        continue
    apps = os.path.join(PAPIRUS, d, "apps")
    if not os.path.isdir(apps):
        continue
    outdir = os.path.join(DST, d, "apps")
    entries = os.listdir(apps)
    real = {f for f in entries if f in TARGETS and not os.path.islink(os.path.join(apps, f))}
    linked = {f: os.readlink(os.path.join(apps, f)) for f in entries
              if os.path.islink(os.path.join(apps, f)) and os.readlink(os.path.join(apps, f)) in real}
    if not real and not linked:
        continue
    os.makedirs(outdir, exist_ok=True)
    for f in sorted(real):
        with open(os.path.join(apps, f)) as fh:
            content = fh.read()
        with open(os.path.join(outdir, f), "w") as fh:
            fh.write(remap(content))
        sysicons += 1
    for f, tgt in sorted(linked.items()):
        link = os.path.join(outdir, f)
        if os.path.lexists(link):
            os.remove(link)
        os.symlink(tgt, link)
        aliases += 1

# --------------------------------- layer 3: Nordzy full reforge (no places)
reforged = links = 0
for root, dirs, files in os.walk(NORDZY, followlinks=False):
    rel = os.path.relpath(root, NORDZY)
    if rel.split(os.sep)[0] == "places" or (os.sep + "places") in (os.sep + rel):
        continue
    outdir = os.path.join(DST, rel) if rel != "." else DST
    for f in files:
        src = os.path.join(root, f)
        dst = os.path.join(outdir, f)
        if os.path.islink(src):
            tgt = os.readlink(src)
            if "/places/" in tgt or tgt.startswith("places/"):
                continue
            os.makedirs(outdir, exist_ok=True)
            if os.path.lexists(dst):
                os.remove(dst)
            os.symlink(tgt, dst)
            links += 1
        elif f.endswith(".svg"):
            os.makedirs(outdir, exist_ok=True)
            with open(src, errors="ignore") as fh:
                content = fh.read()
            with open(dst, "w") as fh:
                fh.write(remap(content))
            reforged += 1
        elif f == "index.theme" or f.endswith(".cache"):
            continue
        else:
            os.makedirs(outdir, exist_ok=True)
            with open(src, "rb") as fh:
                data = fh.read()
            with open(dst, "wb") as fh:
                fh.write(data)

# ------------------------------- index.theme: merged Papirus+Nordzy layouts
def parse_index(path):
    text = open(path).read()
    m = re.search(r"^Directories=(.+)$", text, re.M)
    dirs = m.group(1).split(",") if m else []
    m2 = re.search(r"^ScaledDirectories=(.+)$", text, re.M)
    sdirs = m2.group(1).split(",") if m2 else []
    sections = re.findall(r"(\n\[[^\]]+\]\n(?:(?!\n\[).*\n?)*)", text)
    return dirs, sdirs, sections

p_dirs, p_sdirs, p_sec = parse_index(os.path.join(PAPIRUS, "index.theme"))
n_text = open(os.path.join(NORDZY, "index.theme")).read()
n_dirs, n_sdirs, n_sec = parse_index(os.path.join(NORDZY, "index.theme"))

dirs, seen = [], set()
for d in p_dirs + n_dirs:
    if d and d not in seen:
        seen.add(d); dirs.append(d)
sdirs, seen2 = [], set()
for d in p_sdirs + n_sdirs:
    if d and d not in seen2:
        seen2.add(d); sdirs.append(d)

sec_map = {}
for s in p_sec + n_sec:
    hdr = s.strip().splitlines()[0]
    sec_map.setdefault(hdr, s)

header = re.split(r"\n\[[^\]]+\]", n_text)[0]
header = re.sub(r"^Name=.*$", "Name=Synthwave84", header, flags=re.M)
header = re.sub(r"^Comment=.*$",
                "Comment=Synthwave84 Mercenary - steel and blood. Nordzy-dark reforged, Papirus blood folders.",
                header, flags=re.M)
inherits = ("Inherits=Papirus-Dark,breeze-dark,hicolor" if FALLBACK
            else "Inherits=Nordzy-dark,Papirus-Dark,breeze-dark,hicolor")
header = re.sub(r"^Inherits=.*$", inherits, header, flags=re.M)
header = re.sub(r"^Directories=.*$", "Directories=" + ",".join(dirs), header, flags=re.M)
if "ScaledDirectories=" in header:
    header = re.sub(r"^ScaledDirectories=.*$", "ScaledDirectories=" + ",".join(sdirs),
                    header, flags=re.M)
elif sdirs:
    header += "\nScaledDirectories=" + ",".join(sdirs) + "\n"

with open(os.path.join(DST, "index.theme"), "w") as fh:
    fh.write(header.rstrip() + "\n" + "".join(sec_map.values()))

# core place aliases Dolphin expects (Papirus symlinks these to folder.svg;
# symlink aliases get pruned as broken, so forge real copies)
import shutil as _sh
_aliases = ["inode-directory", "folder-open", "folder-visiting", "folder-remote", "gtk-directory"]
_afixed = 0
for _root, _dirs, _files in os.walk(DST):
    if os.path.basename(_root) != "places" or "folder.svg" not in _files:
        continue
    for _a in _aliases:
        _dst = os.path.join(_root, _a + ".svg")
        if not os.path.exists(_dst):
            _sh.copy2(os.path.join(_root, "folder.svg"), _dst)
            _afixed += 1
print(f"place-alias-copies={_afixed}")

# drop any symlinks that broke during the merge
broken = 0
for root, dirs, files in os.walk(DST):
    for f in files:
        p = os.path.join(root, f)
        if os.path.islink(p) and not os.path.exists(p):
            os.remove(p)
            broken += 1

# --------------------------------- layer 4: blood Kickoff category glyphs
# Kickoff's sidebar renders categories/symbolic/*.svg with their own fill
# (nord light gray #d8dee9). Recolor to canon blood.
catsym = 0
csdir = os.path.join(DST, "categories", "symbolic")
if os.path.isdir(csdir):
    for f in os.listdir(csdir):
        if not f.endswith(".svg"):
            continue
        p = os.path.join(csdir, f)
        with open(p) as fh:
            content = fh.read()
        new = re.sub(r"#d8dee9", "#FF7EDB", content, flags=re.I)
        if new != content:
            with open(p, "w") as fh:
                fh.write(new)
            catsym += 1

# ------------------------------- layer 5: cachy-update tray icons (hicolor-only)
# arch-update ships its tray icons ONLY in hicolor (cyan #0cf body, red #f93a30
# alert) which clashes with the steel+blood panel. Reforge the two blue-variant
# states into bone/ash + blood so they survive theme rebuilds.
import pathlib
cu_src = pathlib.Path("/usr/share/icons/hicolor/scalable/apps")
cu_out = os.path.join(DST, "apps", "scalable")
CU_MAP = {
    "cachy-update-blue.svg": {
        "#0fc": "#FFFFFF", "#0cf": "#FFFFFF", "#00f8c6": "#FFFFFF",
        "#00e6b8": "#E4DED2", "#00c9a1": "#C9C3B7", "#00a281": "#9B968A",
        "#008066": "#6E7278", "#0a8": "#B084EB",
    },
    "cachy-update_updates-available-blue.svg": {
        "#0cf": "#FF7EDB", "#0a8": "#B084EB", "#f93a30": "#FF7EDB",
    },
}
cu_icons = 0
os.makedirs(cu_out, exist_ok=True)
for fname, mapping in CU_MAP.items():
    src = cu_src / fname
    if not src.is_file():
        continue
    content = src.read_text()
    for old, new in mapping.items():
        content = content.replace(old, new)
    with open(os.path.join(cu_out, fname), "w") as fh:
        fh.write(content)
    cu_icons += 1

print(f"folders={folders} sysicons={sysicons} aliases={aliases} "
      f"nordzy-reforged={reforged} nordzy-links={links} broken-pruned={broken} "
      f"category-glyphs-bled={catsym} cachy-update-reforged={cu_icons}")
PYEOF

# --------------------------------- layer 6: hand-forged custom app icons
# Repo-owned one-offs (configs/icons/custom/) that no parent theme ships in
# Synthwave84 livery. The custom/ tree mirrors theme-relative paths
# (apps/scalable/..., status/22/...) and overwrites the parent-forged set on
# every rebuild, so edits survive re-runs of this script.
CUSTOM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/custom"
customs=0
if [[ -d "$CUSTOM_DIR" ]]; then
  while IFS= read -r svg; do
    rel="${svg#"$CUSTOM_DIR"/}"
    mkdir -p "$DST/$(dirname "$rel")"
    cp "$svg" "$DST/$rel"
    customs=$((customs+1))
  done < <(find "$CUSTOM_DIR" -name '*.svg')
  # Ghostty ships no generic-name icon anywhere; alias it to the app-id icon.
  if [[ -f "$DST/apps/scalable/com.mitchellh.ghostty.svg" && ! -e "$DST/apps/scalable/ghostty.svg" ]]; then
    ln -s com.mitchellh.ghostty.svg "$DST/apps/scalable/ghostty.svg"
  fi
fi
echo "customs-forged=$customs"

echo "Done. Activate with:"
echo "  kwriteconfig6 --file ~/.config/kdeglobals --group Icons --key Theme Synthwave84-Icons"
echo "  kbuildsycoca6 --noincremental && systemctl --user restart plasma-plasmashell.service"
