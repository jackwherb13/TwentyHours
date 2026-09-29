"""Cache the requested public RAC web references, with provenance. Never creates textures."""
import hashlib
import json
import re
import urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'reference/web'
SOURCES={
    'rac_facility':'https://recreation.gmu.edu/facilities/rac/',
    'rac_virtual_tour':'https://oips.gmu.edu/managing-your-academic-workload/',
    'rac_addition_status':'https://construction.gmu.edu/bapc-rac-addition',
}


def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=30) as response:
        return response.read()


def main():
    OUT.mkdir(parents=True,exist_ok=True);manifest=[]
    for key,url in SOURCES.items():
        try:
            data=fetch(url);path=OUT/f'architect_{key}.html';path.write_bytes(data)
            manifest.append(dict(url=url,file=str(path.relative_to(ROOT)),sha256=hashlib.sha256(data).hexdigest(),use='Architectural reference only; never a character or people texture'))
            if key=='rac_facility':
                urls=re.findall(r'https://[^\s"<>]+\.(?:jpg|png)',data.decode('utf-8','replace'))
                candidate=next((u for u in urls if 'rac' in u.lower() and 'logo' not in u.lower()),None)
                if candidate:
                    pic=fetch(candidate);imagepath=OUT/'architect_rac_facility_photo.jpg';imagepath.write_bytes(pic)
                    manifest.append(dict(url=candidate,file=str(imagepath.relative_to(ROOT)),sha256=hashlib.sha256(pic).hexdigest(),use='Reference only; people must not become game assets'))
            print('SAVED',url)
        except Exception as e:
            manifest.append(dict(url=url,error=str(e)));print('FETCH FAILED',url,type(e).__name__)
    (OUT/'architect_sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (ROOT/'blueprint/web_sources.json').write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__':main()
