"""Blueprint <-> geographic transform matching tools/site/prepare_site.py."""
import math

LAT0, LON0 = 38.8322, -77.3124
ANGLE = math.radians(10.43)
C, S = math.cos(ANGLE), math.sin(ANGLE)
FT = 1 / 0.3048


def raw_geo(lat, lon):
    e = (lon - LON0) * 111320 * math.cos(math.radians(LAT0)) * FT
    n = (lat - LAT0) * 111320 * FT
    return e * C - n * S, -e * S - n * C


ANCHOR = raw_geo(38.8310914, -77.312432)
SHIFT = [-199.5 - ANCHOR[0], -204.5 - ANCHOR[1]]


def geo(lat, lon):
    x, z = raw_geo(lat, lon)
    return [round(x + SHIFT[0], 2), round(z + SHIFT[1], 2)]


def inverse(x, z):
    x, z = x - SHIFT[0], z - SHIFT[1]
    e, n = x * C - z * S, -x * S - z * C
    return LAT0 + n / (111320 * FT), LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)
