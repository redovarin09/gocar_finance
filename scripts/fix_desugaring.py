import re, os

for f in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    if not os.path.exists(f):
        print(f'Skip: {f}')
        continue

    txt = open(f).read()
    is_kts = f.endswith('.kts')

    print(f'\n=== {f} ===')
    for ln in txt.splitlines():
        if any(k in ln for k in ['compileOptions','dependencies','desugar','coreLibrary','sourceCompat']):
            print(f'  {ln}')

    # Fix isCoreLibraryDesugaringEnabled
    flag = 'isCoreLibraryDesugaringEnabled'
    if flag not in txt:
        val = 'isCoreLibraryDesugaringEnabled = true' if is_kts \
              else 'coreLibraryDesugaringEnabled true'
        txt = re.sub(
            r'(sourceCompatibility\s*[=\s]+JavaVersion\.[A-Z_0-9]+)',
            rf'{val}\n        \1',
            txt
        )
        print(f'Added desugar flag')

    # Fix dependency
    if 'desugar_jdk_libs' not in txt:
        line = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' \
               if is_kts else \
               "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'"
        for pat in ['dependencies {', 'dependencies{']:
            idx = txt.rfind(pat)
            if idx != -1:
                pos = idx + len(pat)
                txt = txt[:pos] + '\n' + line + txt[pos:]
                print(f'Added desugar dep')
                break

    open(f, 'w').write(txt)
    print(f'Done: {f}')
