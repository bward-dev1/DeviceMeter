# Sideloading DeviceMeter

## Quick Start

DeviceMeter is built as an unsigned IPA for sideloading on iPad Pro 2020. No developer account needed.

### Step 1: Download the IPA

Download the latest DeviceMeter IPA from the [Releases](../../releases) page. The file will be named `DeviceMeter.ipa`.

### Step 2: Sideload with Your Tool of Choice

#### Option A: AltStore (Recommended)

1. Install [AltStore](https://altstore.io/) on your Mac
2. Connect your iPad via USB
3. Open AltStore and tap the **+** icon
4. Select the `DeviceMeter.ipa` file
5. Follow the on-screen prompts
6. Device will appear as "Untrusted Developer" — go to **Settings → General → Device Management** and tap "Trust"

#### Option B: LiveContainer (on-device sideloader)

1. Install [LiveContainer](https://livecontainer.io/) via AltStore or another sideloader
2. Open LiveContainer on your iPad
3. Add the `DeviceMeter.ipa` file
4. Tap Install

#### Option C: Sideloadly (Windows/Mac)

1. Download [Sideloadly](https://sideloadly.io/)
2. Connect iPad via USB (or Wi-Fi)
3. Drag `DeviceMeter.ipa` into Sideloadly
4. Select your device and sideload
5. Trust the developer on device

### Step 3: Trust the Developer

On iPad:
- **Settings → General → Device Management**
- Find "Brandon Ward" or the certificate
- Tap **Trust "Brandon Ward"**

### Step 4: Launch & Test

1. Open **DeviceMeter** from the home screen
2. Tap **Benchmarks** tab → **Run Benchmarks** to start
3. Run all 5 test suites (Device, Benchmarks, Thermal, Storage, Display)
4. Take screenshots of each tab to compare devices

## Test Sequence (iPad 1)

1. **Device Tab**: Screenshot device profile (GPU family, RAM, CPU cores)
2. **Benchmarks Tab**: Run benchmarks, screenshot results
3. **Thermal Tab**: Run 30–60s thermal stress test, note any drops
4. **Storage Tab**: Run I/O test, note read/write speeds
5. **Display Tab**: Screenshot display specs

Repeat on iPad 2 and compare side-by-side.

## What to Compare

| Metric | Meaning |
|--------|---------|
| **Performance Tier** | GPU family (A12Z vs others) |
| **CPU Ops/sec** | Integer and float throughput |
| **Memory BW** | GB/sec at different buffer sizes |
| **Thermal Test** | Whether device throttles under sustained load |
| **Storage Speed** | Write/read MB/s (SSD variance) |
| **Display** | Resolution, brightness, refresh rate |

## Building From Source

If you want to rebuild the IPA locally:

```bash
cd ~/DeviceMeter
xcodegen generate
xcodebuild archive \
  -scheme DeviceMeter \
  -configuration Release \
  -sdk iphoneos \
  -archivePath build/DeviceMeter.xcarchive \
  CODE_SIGNING_REQUIRED=NO
```

Then extract the IPA from the archive.

## Troubleshooting

**"This app cannot be installed because its integrity could not be verified."**
- Ensure the IPA was downloaded completely
- Try re-sideloading with a different tool

**"Untrusted Developer" after installation**
- Go to **Settings → General → Device Management**
- Tap the certificate and choose **Trust**

**App crashes on launch**
- Ensure iOS 16.0 or later (iPad Pro 2020 comes with 16.5+)
- Try reinstalling via a different sideload tool

**Benchmarks don't run**
- Ensure the app is trusted (see above)
- Try force-closing and reopening
- Check available storage (needs ~100 MB free)

## Performance Notes

- **CPU benchmarks** scale to 10–50M iterations based on device tier
- **Thermal test** runs for 30 seconds by default (adjustable)
- **Storage test** uses 10 MB temp file (requires write permissions)
- **GPU benchmarks** use Metal blit commands for compatibility

## Authors

Brandon Ward — DeviceMeter v1.0
