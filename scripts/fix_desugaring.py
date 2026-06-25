import re, os

for f in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    if not os.path.exists(f):
        print(f'Skip: {f}')
        continue

    txt  = open(f).read()
    is_kts = f.endswith('.kts')
    orig = txt

    # Print full content untuk debug
    print(f'\n====== FULL CONTENT: {f} ======')
    print(txt)
    print(f'====== END {f} ======')

    # Fix flag
    flag = 'isCoreLibraryDesugaringEnabled'
    if flag not in txt:
        val = 'isCoreLibraryDesugaringEnabled = true' if is_kts \
              else 'coreLibraryDesugaringEnabled true'
        new = re.sub(
            r'(sourceCompatibility\s*[=\s]+JavaVersion\.[A-Z_0-9]+)',
            rf'{val}\n        \1', txt
        )
        txt = new if new != txt else re.sub(
            r'(compileOptions\s*\{)',
            rf'\1\n        {val}', txt
        )
        print('Flag added:', flag in txt)

    # Fix dependency — pakai regex handles semua whitespace
    if 'desugar_jdk_libs' not in txt:
        line = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")' \
               if is_kts else \
               "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.3'"

        matches = list(re.finditer(r'dependencies\s*\{', txt))
        print(f'Found {len(matches)} dependencies block(s)')
        if matches:
            pos = matches[-1].end()
            txt = txt[:pos] + '\n' + line + txt[pos:]
            print('Dep added:', 'desugar_jdk_libs' in txt)
        else:
            txt += f'\ndependencies {{\n{line}\n}}\n'
            print('Appended new dependencies block')

    if txt != orig:
        open(f,'w').write(txt)
        print(f'Written: {f}')
    else:
        print(f'No changes: {f}')
