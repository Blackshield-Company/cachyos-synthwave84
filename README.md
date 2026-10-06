# cachyos-synthwave84

Fresh CachyOS install → the full grid, one script.
**Theme: Synthwave '84** — deep purple `#240037`, hot pink `#FF7EDB`,
electric purple `#8F00FF`, magenta `#FF00FF`, neon yellow `#F3E70F`, cyan `#03EDF9`.
Type: 3270 Nerd Font. Not amber. Not olive. Not a CRT costume.

Public theme grid for a fresh CachyOS install. Personal project library
and local model config are not in this repo. `./install.sh` deploys the
desktop theme only.


## Palette

| Role | Hex |
|---|---|
| Background | `#240037` |
| Foreground | `#FF7EDB` |
| Purple | `#8F00FF` |
| Magenta | `#FF00FF` |
| Yellow | `#F3E70F` |
| Cyan | `#03EDF9` |
| Red | `#FE4450` |
| Green | `#72F1B8` |

Window chrome uses `#240037`, never `#0D0221`.

## One-liner (fresh box)

```bash
sudo pacman -S --needed --noconfirm git github-cli && gh auth login \
  && gh repo clone synthalorian/cachyos-synthwave84 \
  && cd cachyos-synthwave84 && ./install.sh
```

Run one phase: `./install.sh configs` (or browsers/system/packages/nvim).

## Boot safety

`configs/limine/limine.conf` below the first `/+` marker is a stale snapshot.
Never copy the whole file over `/boot/limine.conf`. `handoff-post-reboot.sh`
splices the theme block only and keeps live kernel entries.

## After install

1. Log out/in
2. `sudo -E bash handoff-post-reboot.sh` from this repo after the first reboot
