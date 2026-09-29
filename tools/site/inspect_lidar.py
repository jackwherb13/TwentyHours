import sys,json
from pathlib import Path
sys.path.insert(0,str(Path('tools/site/.vendor').resolve()));sys.modules['pyproj']=None
import laspy
with laspy.open('reference/web/rac_lidar_2022.laz',read_evlrs=False) as f:
 print('POINTS',f.header.point_count,'BOUNDS',f.header.mins,f.header.maxs,'SCALE',f.header.scales)
 for v in f.header.vlrs:
  print(type(v).__name__,getattr(v,'string',str(v))[:6000])
