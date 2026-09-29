"""Capture the TwentyHours.rbxl Studio 3D viewport."""
from pathlib import Path
import sys
import time

import ctypes
from ctypes import wintypes
from PIL import Image, ImageGrab

user32 = ctypes.windll.user32
out = Path(sys.argv[1])

length = user32.GetWindowTextLengthW
enum = user32.EnumWindows
get_text = user32.GetWindowTextW
is_vis = user32.IsWindowVisible
set_fg = user32.SetForegroundWindow
get_rect = user32.GetWindowRect

WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
found = []


def cb(hwnd, _lp):
    if not is_vis(hwnd):
        return True
    n = length(hwnd)
    buf = ctypes.create_unicode_buffer(n + 1)
    get_text(hwnd, buf, n + 1)
    if "TwentyHours.rbxl" in buf.value:
        found.append(hwnd)
    return True


enum(WNDENUMPROC(cb), 0)
if not found:
    raise SystemExit("TwentyHours.rbxl window not found")
hwnd = found[0]
set_fg(hwnd)
time.sleep(0.25)
rect = wintypes.RECT()
get_rect(hwnd, ctypes.byref(rect))
im = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom))
# Drop Studio chrome: ribbon + explorer. Fractions of the window.
w, h = im.size
crop = im.crop((int(w * 0.18), int(h * 0.12), int(w * 0.82), int(h * 0.92)))
out.parent.mkdir(parents=True, exist_ok=True)
crop.save(out)
print(out, crop.size)
