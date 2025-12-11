# Android Release Signing

This document describes the Android release signing setup for ReadWhere.

## Overview

The app uses a release keystore for signing production APKs. This ensures:

- Users can update the app without reinstalling
- APKs are verified and trusted
- Play Store distribution is possible

## How It Works

The build system checks for signing credentials in this order:

1. **CI Environment Variables** (GitHub Actions) - Used for release builds
2. **Local key.properties file** - Used for local development releases
3. **Debug keystore** - Fallback if no credentials found

## Local Development Setup

### 1. Obtain the Keystore

Get `readwhere-release.keystore` from the secure team storage.

### 2. Place the Keystore

Copy the keystore to `android/readwhere-release.keystore`.

> This location is git-ignored and will not be committed.

### 3. Create key.properties

Create `android/key.properties` with:

```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=readwhere
storeFile=../readwhere-release.keystore
```

> This file is git-ignored and will not be committed.

### 4. Build Release APK

```bash
flutter build apk --release
```

### 5. Verify Signing

```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

## CI/CD Setup (GitHub Actions)

Release signing is handled automatically via GitHub Secrets.

### Required Secrets

| Secret                       | Description                      |
| ---------------------------- | -------------------------------- |
| `ANDROID_KEYSTORE_BASE64`    | Base64-encoded keystore file     |
| `ANDROID_KEYSTORE_PASSWORD`  | Password for the keystore        |
| `ANDROID_KEY_ALIAS`          | Key alias (typically `readwhere`) |
| `ANDROID_KEY_PASSWORD`       | Password for the key             |

### How to Encode the Keystore

```bash
base64 -i android/readwhere-release.keystore | tr -d '\n' > keystore-base64.txt
```

Copy the contents of `keystore-base64.txt` to the `ANDROID_KEYSTORE_BASE64` secret.

> Delete `keystore-base64.txt` after adding the secret.

## Creating a New Keystore

If you need to generate a new keystore (first-time setup):

```bash
keytool -genkey -v -keystore readwhere-release.keystore \
  -alias readwhere \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**Important**:

- Use strong, unique passwords for both store and key
- Back up the keystore and credentials securely
- If lost, users must uninstall and reinstall the app

## Keystore Recovery

The keystore and credentials should be backed up in a secure location (e.g., password manager, encrypted backup).

**WARNING**: Losing the keystore means existing users cannot update - they must uninstall and reinstall.

## Play Store Considerations

When uploading to Google Play Store:

1. Build an App Bundle instead of APK:

   ```bash
   flutter build appbundle --release
   ```

2. Google Play uses **Play App Signing** by default:
   - Your keystore becomes the "upload key"
   - Google manages the actual "app signing key"
   - This provides recovery options if you lose your upload key

## Troubleshooting

### "App already exists" during update

This occurs when trying to install an APK with a different signature. Solutions:

1. Ensure you're using the same keystore for all builds
2. If signatures differ, users must uninstall the old version first

### Build fails with signing error

Check that:

1. `key.properties` exists and has correct paths
2. Keystore file exists at the specified location
3. Passwords are correct
4. For CI: Verify all GitHub Secrets are set correctly

### Verify APK signature

```bash
# Check if APK is signed
jarsigner -verify build/app/outputs/flutter-apk/app-release.apk

# Show detailed certificate info
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```
