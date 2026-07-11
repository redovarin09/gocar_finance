import os

f = 'android/app/build.gradle.kts'
if not os.path.exists(f):
    print(f'Skip: {f}')
    exit()

txt = open(f).read()

if 'signingConfigs' in txt:
    print('Signing config already exists')
    exit()

# Blok pembacaan key.properties
key_props_block = '''
    // Signing
    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = java.util.Properties()
    if (keyPropertiesFile.exists()) {
        keyProperties.load(java.io.FileInputStream(keyPropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String? ?: ""
            keyPassword = keyProperties["keyPassword"] as String? ?: ""
            storeFile = keyProperties["storeFile"]?.let { file(it as String) }
            storePassword = keyProperties["storePassword"] as String? ?: ""
        }
    }

'''

# Sisipkan sebelum buildTypes
txt = txt.replace(
    '    buildTypes {',
    key_props_block + '    buildTypes {'
)

# Ganti signingConfig debug → release
txt = txt.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)

open(f, 'w').write(txt)
print('Done: signing config added')
print('Verify:')
for i, ln in enumerate(txt.splitlines(), 1):
    if any(k in ln for k in ['signingConfig', 'keyAlias', 'storeFile']):
        print(f'  {i}: {ln}')
