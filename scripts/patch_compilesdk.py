import os, re

FILES = [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
]

COMPILESDK_PATTERNS = [
    (r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 36'),
    (r'compileSdk\s+flutter\.compileSdkVersion',     'compileSdk 36'),
    (r'compileSdk\s*=\s*\d+',                        'compileSdk = 36'),
    (r'compileSdkVersion\s+\d+',                     'compileSdkVersion 36'),
]

for filepath in FILES:
    if not os.path.exists(filepath):
        print(f'Skip: {filepath}')
        continue

    txt  = open(filepath).read()
    orig = txt

    # Fix compileSdk
    for p, r in COMPILESDK_PATTERNS:
        txt = re.sub(p, r, txt)

    # Kotlin DSL (.kts)
    if filepath.endswith('.kts'):
        if 'isCoreLibraryDesugaringEnabled' not in txt:
            txt = re.sub(
                r'(compileOptions\s*\{)',
                r'\1\n        isCoreLibraryDesugaringEnabled = true',
                txt
            )
            print(f'Added isCoreLibraryDesugaringEnabled: {filepath}')

        if 'desugar_jdk_libs' not in txt:
            txt = re.sub(
                r'(dependencies\s*\{)',
                r'\1\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
                txt
            )
            print(f'Added coreLibraryDesugaring dep: {filepath}')

    # Groovy DSL (.gradle)
    else:
        if 'coreLibraryDesugaringEnabled' not in txt:
            txt = re.sub(
                r'(compileOptions\s*\{)',
                r'\1\n        coreLibraryDesugaringEnabled true',
                txt
            )
            print(f'Added coreLibraryDesugaringEnabled: {filepath}')

        if 'desugar_jdk_libs' not in txt:
            txt = re.sub(
                r'(dependencies\s*\{)',
                r"\1\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'",
                txt
            )
            print(f'Added coreLibraryDesugaring dep: {filepath}')

    if txt != orig:
        open(filepath, 'w').write(txt)
        print(f'Patched: {filepath}')
    else:
        lines = [l.strip() for l in txt.splitlines() if 'compileSdk' in l.lower()]
        print(f'No changes in {filepath}, compileSdk lines: {lines}')
