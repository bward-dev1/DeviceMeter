# DeviceMeter — iPad Pro Benchmark & Comparison Tool

A comprehensive device benchmarking app for iOS/iPadOS. Run CPU, GPU, memory, thermal, storage I/O, and display tests to compare performance across devices. Built with SwiftUI, Metal, and XcodeGen for automatic Xcode project generation.

## Features

- **Device Info**: Full hardware profiling (GPU family, RAM, CPU cores, performance tier classification)
- **CPU Benchmarks**: Integer ops, floating-point ops, SIMD vectorized workloads
- **Memory Tests**: Bandwidth measurement across different buffer sizes (1MB, 16MB, 64MB)
- **GPU Benchmarks**: Metal compute shader dispatch throughput
- **Thermal Stress Test**: Sustained load testing to identify thermal throttling
- **Storage I/O**: Sequential read/write speed measurement
- **Display Analysis**: Screen resolution, scale, brightness, refresh rate detection

## Building

### Automatic (CI)

The `.github/workflows/ios-build.yml` workflow automatically builds and releases unsigned IPAs on push to `main`. Download the latest from [Releases](../../releases).

### Local Build

```bash
brew install xcodegen
xcodegen generate
xcodebuild build \
  -scheme DeviceMeter \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=
```

## Sideloading

1. Download the latest `.ipa` from [Releases](../../releases)
2. Use AltStore, LiveContainer, Sideloadly, or another sideload tool
3. Install the unsigned IPA
4. Launch DeviceMeter and run tests

## Results

The app is stateless — results are displayed in-app during testing. Export or screenshot results for comparison between devices:

- **Device 1**: Run all tests, take screenshots of each tab
- **Device 2**: Same test suite on the second device
- **Compare**: Side-by-side screenshots or notes to identify performance gaps

## Architecture

- **DeviceProfile**: Detects GPU family, RAM, CPU cores; classifies into Low/Medium/High/Ultra performance tiers
- **BenchmarkRunner**: Actor-based async benchmark execution with Metal compute integration
- **UI**: SwiftUI multi-tab interface (Device → Benchmarks → Thermal → Storage → Display)

## Requirements

- iOS 16+ (iPad OS 16+)
- Metal 3+ capable GPU (A8 and newer Apple SoCs)

## License

MIT

## Author

Brandon Ward — DeviceMeter v1.0
