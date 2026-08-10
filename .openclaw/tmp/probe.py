import re,base64
s=open('.openclaw/tmp/RS3zNQVk.lua').read()
# mapping S section
m=re.search(r'local S=\{(.*?)\}local X=',s,re.S); print(bool(m),len(m.group(1)))
body=m.group(1)
mp={}
for key, expr in re.findall(r'(?:([A-Za-z])|\["(\\\d{3})"\])\s*=\s*([^,;]+)',body):
 k=key or chr(int(expr if False else 0))
