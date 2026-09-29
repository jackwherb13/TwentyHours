import sys,importlib
sys.path.insert(0,'tools/site/.vendor')
for m in ['numpy','laspy','lazrs','rasterio','shapely','scipy','mapbox_vector_tile']:
 try: x=importlib.import_module(m);print(m,'OK')
 except Exception as e:print(m,type(e).__name__,str(e)[:200])
