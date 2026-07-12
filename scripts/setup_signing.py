import os, re

f = 'android/app/build.gradle.kts'
if not os.path.exists(f):
    print(f'Skip: {f}')
    exit()

txt = open(f).read()

# 1. Tambah import di baris PERTAMA (wajib untuk Kotlin DSL)
if 'import java.util.Properties' not in txt:
    txt = 'import java.util.Properties\n\n' + txt
    print('Added import java.util.Properties')

# 2. Key reader — pakai Properties() tanpa java.util. prefix
key_reader = '''
// Load keystore
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.reader())
}

'''

# Sisipkan setelah plugins block
if 'keyPropertiesFile' not in txt:
    txt = re.sub(
        r'(plugins\s*\{[^}]*\}\s*\n)',
        r'\1' + key_reader,
        txt, count=1
    )
    print('Added key reader')

# 3. signingConfigs block
signing_config = '''
    signingConfigs {
        create("release") {
            keyAlias     = keyProperties["keyAlias"] as String? ?: ""
            keyPassword  = keyProperties["keyPassword"] as String? ?: ""
            storeFile    = keyProperties["storeFile"]?.let { file(it as String) }
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
    print('Added signingConfigs')

# 4. debug → release
count = txt.count('signingConfig = signingConfigs.getByName("debug")')
txt = txt.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)
print(f'Replaced {count} debug → release')

open(f, 'w').write(txt)
print('Done')
