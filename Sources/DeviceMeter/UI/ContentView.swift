import SwiftUI

struct ContentView: View {
    @State private var profile: DeviceProfile?
    @State private var benchmarkRunner: BenchmarkRunner?
    @State private var results: [BenchmarkResult] = []
    @State private var isRunning = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DeviceInfoView(profile: profile)
                .tabItem {
                    Label("Device", systemImage: "ipad.gen1")
                }
                .tag(0)

            BenchmarkView(
                results: results,
                isRunning: isRunning,
                onStartBenchmark: startBenchmarks
            )
            .tabItem {
                Label("Benchmarks", systemImage: "bolt.fill")
            }
            .tag(1)

            ThermalTestView(profile: profile)
                .tabItem {
                    Label("Thermal", systemImage: "thermometer")
                }
                .tag(2)

            StorageTestView()
                .tabItem {
                    Label("Storage", systemImage: "internaldrive")
                }
                .tag(3)

            DisplayTestView()
                .tabItem {
                    Label("Display", systemImage: "display")
                }
                .tag(4)
        }
        .onAppear {
            loadDeviceProfile()
        }
    }

    private func loadDeviceProfile() {
        let prof = DeviceProfile.detect()
        self.profile = prof
        self.benchmarkRunner = BenchmarkRunner(profile: prof)
    }

    private func startBenchmarks() {
        Task {
            isRunning = true
            if let runner = benchmarkRunner {
                await runner.runAllBenchmarks()
                let updatedResults = await runner.results
                self.results = updatedResults
            }
            isRunning = false
        }
    }
}

struct DeviceInfoView: View {
    let profile: DeviceProfile?

    var body: some View {
        NavigationStack {
            if let profile = profile {
                List {
                    Section("Performance Tier") {
                        HStack {
                            Text("Classification")
                            Spacer()
                            Text(profile.tier.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Section("GPU") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledValue("Name", profile.gpuName)
                            LabeledValue("Family", profile.gpuFamily)
                            LabeledValue("Max Threadgroup", "\(profile.maxThreadsPerThreadgroup)")
                            LabeledValue("Non-uniform Support", profile.supportsNonUniformThreadgroups ? "Yes" : "No")
                        }
                    }

                    Section("Memory") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledValue("Physical RAM", formatBytes(profile.physicalMemoryBytes))
                            LabeledValue("Recommended Working Set", formatBytes(profile.recommendedWorkingSetBytes))
                        }
                    }

                    Section("CPU") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledValue("Active Cores", "\(profile.processorCount)")
                        }
                    }
                }
                .navigationTitle("Device Info")
            } else {
                Text("Loading device info...")
            }
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / Double(1 << 30)
        return String(format: "%.1f GB", gb)
    }
}

struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

struct BenchmarkView: View {
    let results: [BenchmarkResult]
    let isRunning: Bool
    let onStartBenchmark: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                if isRunning {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Running benchmarks...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No benchmarks run yet")
                            .font(.headline)
                        Text("Tap the button below to start")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(results, id: \.name) { result in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.name)
                                        .font(.headline)
                                    Text(result.displayValue)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                Button(action: onStartBenchmark) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text(isRunning ? "Running..." : "Run Benchmarks")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRunning)
                .padding()
            }
            .navigationTitle("Benchmarks")
        }
    }
}

struct ThermalTestView: View {
    let profile: DeviceProfile?
    @State private var testDuration: Int = 30
    @State private var isRunning = false
    @State private var thermalLog: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Thermal Stress Test") {
                        Stepper("Duration: \(testDuration)s", value: $testDuration, in: 10...300, step: 10)
                    }

                    if !thermalLog.isEmpty {
                        Section("Thermal Log") {
                            ForEach(thermalLog, id: \.self) { entry in
                                Text(entry)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Button(action: runThermalTest) {
                    HStack {
                        Image(systemName: "thermometer")
                        Text(isRunning ? "Testing..." : "Run Thermal Test")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRunning)
                .padding()
            }
            .navigationTitle("Thermal Test")
        }
    }

    private func runThermalTest() {
        isRunning = true
        thermalLog = ["Starting thermal stress test..."]

        Task {
            let iterations = profile?.benchmarkIterations ?? 10_000_000
            let fullIterations = (testDuration * iterations) / 30

            for i in 0..<(testDuration / 5) {
                let start = CFAbsoluteTimeGetCurrent()
                var sum: Double = 0
                for j in 0..<(fullIterations / (testDuration / 5)) {
                    sum = sqrt(Double(j) * Double(j))
                }
                let elapsed = CFAbsoluteTimeGetCurrent() - start

                let thermalEntry = String(format: "T+%ds: %.2f sec (sum: %.0f)", (i + 1) * 5, elapsed, sum)
                await MainActor.run {
                    thermalLog.append(thermalEntry)
                }
            }

            await MainActor.run {
                thermalLog.append("Thermal test complete")
                isRunning = false
            }
        }
    }
}

struct StorageTestView: View {
    @State private var writeSpeed = 0.0
    @State private var readSpeed = 0.0
    @State private var isRunning = false
    @State private var testLog: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Sequential Write") {
                        if writeSpeed > 0 {
                            HStack {
                                Text("Write Speed")
                                Spacer()
                                Text(String(format: "%.0f MB/s", writeSpeed))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }

                    Section("Sequential Read") {
                        if readSpeed > 0 {
                            HStack {
                                Text("Read Speed")
                                Spacer()
                                Text(String(format: "%.0f MB/s", readSpeed))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }

                    if !testLog.isEmpty {
                        Section("I/O Log") {
                            ForEach(testLog, id: \.self) { entry in
                                Text(entry)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                }

                Button(action: runStorageTest) {
                    HStack {
                        Image(systemName: "internaldrive.fill")
                        Text(isRunning ? "Testing..." : "Run I/O Test")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRunning)
                .padding()
            }
            .navigationTitle("Storage I/O")
        }
    }

    private func runStorageTest() {
        isRunning = true
        testLog = ["Starting storage I/O test..."]
        writeSpeed = 0
        readSpeed = 0

        Task {
            let fileManager = FileManager.default
            let tempDir = FileManager.default.temporaryDirectory
            let testFile = tempDir.appendingPathComponent("iobench.tmp")

            defer { try? fileManager.removeItem(at: testFile) }

            let testSize = 10 * 1024 * 1024
            let data = Data(repeating: UInt8(42), count: testSize)

            let writeStart = CFAbsoluteTimeGetCurrent()
            do {
                try data.write(to: testFile, options: .atomic)
                let writeElapsed = CFAbsoluteTimeGetCurrent() - writeStart
                let writeMBs = Double(testSize) / 1024.0 / 1024.0 / writeElapsed
                await MainActor.run {
                    writeSpeed = writeMBs
                    testLog.append(String(format: "Write: %.0f MB/s", writeMBs))
                }
            } catch {
                await MainActor.run {
                    testLog.append("Write failed: \(error)")
                }
            }

            let readStart = CFAbsoluteTimeGetCurrent()
            if let readData = try? Data(contentsOf: testFile) {
                let readElapsed = CFAbsoluteTimeGetCurrent() - readStart
                let readMBs = Double(testSize) / 1024.0 / 1024.0 / readElapsed
                await MainActor.run {
                    readSpeed = readMBs
                    testLog.append(String(format: "Read: %.0f MB/s", readMBs))
                }
            }

            await MainActor.run {
                testLog.append("Storage test complete")
                isRunning = false
            }
        }
    }
}

struct DisplayTestView: View {
    @State private var displayInfo: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Screen Details") {
                    if displayInfo.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let screen = UIScreen.main
                            let displayInfo = [
                                "Bounds: \(Int(screen.bounds.width)) × \(Int(screen.bounds.height))pt",
                                "Scale: \(String(format: "%.1f", screen.scale))×",
                                "Native Scale: \(String(format: "%.1f", screen.nativeScale))×",
                                "Native Bounds: \(Int(screen.nativeBounds.width)) × \(Int(screen.nativeBounds.height))px",
                                "Brightness: \(String(format: "%.0f%%", screen.brightness * 100))"
                            ]

                            ForEach(displayInfo, id: \.self) { info in
                                HStack {
                                    Text(info)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        ForEach(displayInfo, id: \.self) { info in
                            Text(info)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }

                Section("Color Space") {
                    if #available(iOS 17, *) {
                        Text("Color space detection requires iOS 17+")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Display Info")
        }
    }
}
