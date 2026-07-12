import os, re

f = 'android/app/build.gradle.kts'
if not os.path.exists(f):
    print(f'Skip: {f}')
    exit()

txt = open(f).read()
print('=== Before fix ===')
for i, ln in enumerate(txt.splitlines(), 1):
    if any(k in ln for k in ['signingConfig', 'signing', 'debug']):
        print(f'  {i}: {ln}')

# Tambah key.properties reader sebelum android {
key_reader = '''
// Load keystore properties
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = java.util.Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(java.io.FileInputStream(keyPropertiesFile))
}

'''

if 'keyPropertiesFile' not in txt:
    txt = key_reader + txt
    print('Added key.properties reader')

# Tambah signingConfigs block sebelum buildTypes
signing_config = '''
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String? ?: ""
            keyPassword = keyProperties["keyPassword"] as String? ?: ""
            storeFile = keyProperties["storeFile"]?.let { file(it as String) }
            storePassword = keyProperties["storePassword"] as String? ?: ""
        }
    }

'''

if 'signingConfigs' not in txt:
    txt = re.sub(
        r'(\s*buildTypes\s*\{)',
        signing_config + r'\1',
        txt, count=1
    )
    print('Added signingConfigs block')

# Ganti SEMUA signingConfig debug → release
old_debug = 'signingConfig = signingConfigs.getByName("debug")'
new_release = 'signingConfig = signingConfigs.getByName("release")'

count = txt.count(old_debug)
txt = txt.replace(old_debug, new_release)
print(f'Replaced {count} debug signingConfig → release')

open(f, 'w').write(txt)
print('=== After fix ===')
for i, ln in enumerate(txt.splitlines(), 1):
    if any(k in ln for k in ['signingConfig', 'keyAlias', 'storeFile']):
        print(f'  {i}: {ln}')
print('Done')
