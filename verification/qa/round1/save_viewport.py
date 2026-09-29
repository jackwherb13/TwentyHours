"""Crop the Roblox Studio 3D viewport (right-hand pane) and save PNG."""
from __future__ import annotations

import ctypes
import sys
from ctypes import wintypes
from pathlib import Path

from PIL import ImageGrab

user32 = ctypes.windll.user32
user32.SetProcessDPIAware()

class RECT(ctypes.Structure):
    _fields_ = [
        ("left", wintypes.LONG),
        ("top", wintypes.LONG),
        ("right", wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]


def studio_hwnd() -> int:
    buf = ctypes.create_unicode_buffer(512)

    def _enum(hwnd, _):
        if not user32.IsWindowVisible(hwnd):
            return True
        user32.GetWindowTextW(hwnd, buf, 512)
        title = buf.value
        if "Roblox Studio" in title and ("20 Hour Weeks" in title or "TwentyHours" in title):
            hwnds.append(hwnd)
        return True

    hwnds: list[int] = []
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
    user32.EnumWindows(WNDENUMPROC(_enum), 0)
    if not hwnds:
        raise SystemExit("Studio window not found")
    return hwnds[0]


def main() -> None:
    out = Path(sys.argv[1])
    hwnd = studio_hwnd()
    user32.SetForegroundWindow(hwnd)
    rect = RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    w = rect.right - rect.left
    h = rect.bottom - rect.top
    # Terrain Editor left, 3D center, Explorer right.
    left = rect.left + int(w * 0.28)
    top = rect.top + int(h * 0.12)
    right = rect.left + int(w * 0.72)
    bottom = rect.bottom - 56
    im = ImageGrab.grab(bbox=(left, top, right, bottom))
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out)
    print(f"{out} {im.size} win={w}x{h} box=({left},{top},{right},{bottom})")


if __name__ == "__main__":
    main()
