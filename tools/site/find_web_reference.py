import requests,re,json
from pathlib import Path
url='https://recreation.gmu.edu/facilities/rac/'
html=requests.get(url,timeout=40).text
links=sorted(set(re.findall(r'https://[^\s\"<>]+\.(?:jpg|png)',html)))
print(links)
Path('reference/web/web_sources.json').write_text(json.dumps({'page':url,'images':links},indent=2))
