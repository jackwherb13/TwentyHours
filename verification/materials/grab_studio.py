"""Screenshot the 20 Hour Weeks Studio 3D viewport."""
from pathlib import Path
import sys
import time
import ctypes
from ctypes import wintypes
from PIL import ImageGrab

user32 = ctypes.windll.user32
out = Path(sys.argv[1])

WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
found = []


def cb(hwnd, _lp):
    if not user32.IsWindowVisible(hwnd):
        return True
    n = user32.GetWindowTextLengthW(hwnd)
    buf = ctypes.create_unicode_buffer(n + 1)
    user32.GetWindowTextW(hwnd, buf, n + 1)
    if "20 Hour Weeks" in buf.value and "Roblox Studio" in buf.value:
        found.append(hwnd)
    return True


user32.EnumWindows(WNDENUMPROC(cb), 0)
if not found:
    raise SystemExit("20 Hour Weeks Studio window not found")
hwnd = found[0]
user32.SetForegroundWindow(hwnd)
time.sleep(0.2)
rect = wintypes.RECT()
user32.GetWindowRect(hwnd, ctypes.byref(rect))
im = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom))
w, h = im.size
# Drop ribbon, explorer, properties, output.
crop = im.crop((int(w * 0.18), int(h * 0.12), int(w * 0.80), int(h * 0.88)))
out.parent.mkdir(parents=True, exist_ok=True)
crop.save(out)
print(out, crop.size)
