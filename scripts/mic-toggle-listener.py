#!/usr/bin/env python3
"""mic-toggle-listener: toggle PipeWire default source mute on a hotkey.

Runs as root (systemd). Watches all by-id *-event-kbd devices for the
configured key (default KEY_V, non-consuming) and toggles the user's
default audio source mute via wpctl, with an OSD notification.
"""
import glob
import os
import subprocess
import sys

import re
import subprocess
import sys

import evdev
from evdev import ecodes as e

KEY = os.environ.get("MIC_TOGGLE_KEY", "KEY_V")
USER = os.environ.get("MIC_TOGGLE_USER", "synth")
UID = os.environ.get("MIC_TOGGLE_UID", "1000")
RUNTIME = f"/run/user/{UID}"

def run_as_user(*args, capture=False):
    return subprocess.run(
        ["runuser", "-u", USER, "--",
         "env", f"XDG_RUNTIME_DIR={RUNTIME}",
         f"DBUS_SESSION_BUS_ADDRESS=unix:path={RUNTIME}/bus"] + list(args),
        check=False, capture_output=capture, text=True)

def vesktop_capture_streams():
    """IDs of Vesktop's mic capture streams (per-app, NOT the source)."""
    out = run_as_user("pactl", "list", "source-outputs", capture=True).stdout or ""
    ids = []
    cur_id = None
    cur_props = ""
    for line in out.splitlines() + ["Source Output #0"]:
        m = re.match(r"Source Output #(\d+)", line)
        if m:
            if cur_id is not None and re.search(
                    r'application\.process\.binary = "[^"]*vesktop', cur_props, re.I):
                ids.append(cur_id)
            cur_id = m.group(1)
            cur_props = ""
        else:
            cur_props += line + "\n"
    return ids

def set_streams_mute(ids, muted):
    for sid in ids:
        run_as_user("pactl", "set-source-output-mute", sid, "1" if muted else "0")

class PushToMute:
    """Hold KEY -> Vesktop's mic stream muted; release -> restored."""
    def __init__(self):
        self.muted = []

    def down(self):
        if self.muted:
            return
        ids = vesktop_capture_streams()
        if ids:
            set_streams_mute(ids, True)
            self.muted = ids

    def up(self):
        if self.muted:
            set_streams_mute(self.muted, False)
            self.muted = []

def main():
    paths = sorted(glob.glob("/dev/input/by-id/*-event-kbd"))
    if not paths:
        print("no *-event-kbd devices found", file=sys.stderr)
        sys.exit(1)
    devices = []
    for p in paths:
        try:
            d = evdev.InputDevice(p)
            devices.append(d)
            print(f"listening: {d.name} ({p})", flush=True)
        except Exception as ex:
            print(f"skip {p}: {ex}", file=sys.stderr)
    keycode = getattr(e, KEY)
    ptm = PushToMute()
    fds = {d.fd: d for d in devices}
    import selectors
    sel = selectors.DefaultSelector()
    for d in devices:
        sel.register(d, selectors.EVENT_READ)
    while True:
        for key, _ in sel.select():
            dev = key.fileobj
            try:
                for event in dev.read():
                    if event.type == e.EV_KEY and event.code == keycode:
                        if event.value == 1:      # key down
                            ptm.down()
                        elif event.value == 0:    # key up
                            ptm.up()
                        # value == 2 is autorepeat: ignore
            except OSError:
                # device unplugged; drop it
                sel.unregister(dev)

if __name__ == "__main__":
    main()
