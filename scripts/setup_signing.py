import os, re

f = 'android/app/build.gradle.kts'
if not os.path.exists(f):
    print(f'Skip: {f}')
    exit()

txt = open(f).read()
print('=== Original buildTypes area ===')
for i, ln in enumerate(txt.splitlines(), 1):
    if any(k in ln for k in ['buildTypes','signingConfig','release','debug']):
        print(f'  {i}: {ln}')

# Step 1: Import di baris pertama
if 'import java.util.Properties' not in txt:
    txt = 'import java.util.Properties\n' + txt
    print('Added import')

# Step 2: Key reader setelah plugins block
if 'keyPropertiesFile' not in txt:
    key_reader = (
        '\nval keyPropertiesFile = rootProject.file("key.properties")\n'
        'val keyProperties = Properties()\n'
        'if (keyPropertiesFile.exists()) {\n'
        '    keyProperties.load(keyPropertiesFile.reader())\n'
        '}\n'
    )
    # Sisipkan setelah baris plugins { ... }
    txt = re.sub(
        r'(plugins\s*\{[^}]*\})',
        r'\1' + key_reader,
        txt, count=1
    )
    print('Added key reader')

# Step 3: signingConfigs INSIDE android{} BEFORE buildTypes
if 'signingConfigs {' not in txt and 'signingConfigs{' not in txt:
    signing = (
        '\n    signingConfigs {\n'
        '        create("release") {\n'
        '            keyAlias     = keyProperties["keyAlias"] as String? ?: ""\n'
        '            keyPassword  = keyProperties["keyPassword"] as String? ?: ""\n'
        '            storeFile    = keyProperties["storeFile"]?.let { file(it as String) }\n'
        '            storePassword = keyProperties["storePassword"] as String? ?: ""\n'
        '        }\n'
        '    }\n'
    )
    # Cari buildTypes di dalam android block
    txt = re.sub(
        r'(\n    buildTypes\s*\{)',
        signing + r'\1',
        txt, count=1
    )
    print('Added signingConfigs before buildTypes')

# Step 4: Ganti debug -> release
count = txt.count('getByName("debug")')
txt = txt.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)
print(f'Replaced {count} debug → release')

open(f, 'w').write(txt)

print('\n=== Final result ===')
for i, ln in enumerate(txt.splitlines(), 1):
    if any(k in ln for k in ['signingConfig','signingConfigs','keyAlias','storeFile','keyProp']):
        print(f'  {i}: {ln}')
print('Done')
