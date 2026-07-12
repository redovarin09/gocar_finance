import os, re

f = 'android/app/build.gradle.kts'
if not os.path.exists(f):
    print(f'Skip: {f}')
    exit()

txt = open(f).read()

# Key reader - pakai .reader() bukan FileInputStream
key_reader = '''
// Load keystore
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = java.util.Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.reader())
}

'''

# Sisipkan SETELAH plugins block (bukan di awal file)
if 'keyPropertiesFile' not in txt:
    txt = re.sub(
        r'(plugins\s*\{[^}]*\}\s*\n)',
        r'\1' + key_reader,
        txt, count=1
    )
    print('Added key reader after plugins block')

# Tambah signingConfigs
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

# Ganti debug → release
count = txt.count('signingConfig = signingConfigs.getByName("debug")')
txt = txt.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)
print(f'Replaced {count} debug → release')

open(f, 'w').write(txt)
print('Done')
