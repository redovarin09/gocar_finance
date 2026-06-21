import os, re

FILES = [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
]

PATTERNS = [
    (r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 36'),
    (r'compileSdk\s+flutter\.compileSdkVersion',     'compileSdk 36'),
    (r'compileSdk\s*=\s*\d+',                        'compileSdk = 36'),
    (r'compileSdkVersion\s+\d+',                     'compileSdkVersion 36'),
]

for filepath in FILES:
    if not os.path.exists(filepath):
        print(f'Skip: {filepath}')
        continue
    txt = open(filepath).read()
    orig = txt
    for p, r in PATTERNS:
        txt = re.sub(p, r, txt)
    if txt != orig:
        open(filepath, 'w').write(txt)
        print(f'Patched: {filepath}')
    else:
        lines = [l.strip() for l in txt.splitlines() if 'compileSdk' in l.lower()]
        print(f'No match in {filepath}')
        print(f'compileSdk lines: {lines}')
