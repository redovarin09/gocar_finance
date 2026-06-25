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

    is_kts = filepath.endswith('.kts')

    # ── Fix isCoreLibraryDesugaringEnabled ──────────────────
    desugar_flag    = 'isCoreLibraryDesugaringEnabled' if is_kts \
                      else 'coreLibraryDesugaringEnabled'
    desugar_flag_val = 'isCoreLibraryDesugaringEnabled = true' if is_kts \
                       else 'coreLibraryDesugaringEnabled true'

    if desugar_flag not in txt:
        txt = re.sub(
            r'(compileOptions\s*\{)',
            rf'\1\n        {desugar_flag_val}',
            txt
        )
        print(f'Added {desugar_flag}: {filepath}')

    # ── Fix coreLibraryDesugaring dependency ────────────────
    # Pakai rfind → target LAST dependencies block (app block)
    if 'desugar_jdk_libs' not in txt:
        dep_line = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' \
                   if is_kts else \
                   "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'"

        last_idx = txt.rfind('dependencies {')
        if last_idx != -1:
            insert_pos = last_idx + len('dependencies {')
            txt = (
                txt[:insert_pos]
                + '\n' + dep_line
                + txt[insert_pos:]
            )
            print(f'Added desugar dep to last dependencies block: {filepath}')
        else:
            print(f'WARNING: dependencies block not found in {filepath}')

    if txt != orig:
        open(filepath, 'w').write(txt)
        print(f'Patched: {filepath}')
    else:
        print(f'No changes: {filepath}')
