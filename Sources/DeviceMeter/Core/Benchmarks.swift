import Foundation
import Metal
import MetalKit

struct BenchmarkResult: Codable {
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date

    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(number) \(unit)"
    }
}

actor BenchmarkRunner {
    private let profile: DeviceProfile
    private(set) var results: [BenchmarkResult] = []
    private(set) var isRunning = false

    init(profile: DeviceProfile) {
        self.profile = profile
    }

    func runAllBenchmarks() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        results = []

        await runCPUBenchmarks()
        await runMemoryBenchmarks()
        if let device = MTLCreateSystemDefaultDevice() {
            await runGPUBenchmarks(device: device)
        }
    }

    private func runCPUBenchmarks() async {
        let iterations = profile.benchmarkIterations

        let start = CFAbsoluteTimeGetCurrent()
        var sum: UInt64 = 0
        for i in 0..<iterations {
            sum = sum &+ UInt64(bitPattern: Int64(i))
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let opsPerSec = Double(iterations) / elapsed
        results.append(BenchmarkResult(
            name: "CPU Integer Ops",
            value: opsPerSec / 1_000_000_000,
            unit: "G ops/sec",
            timestamp: Date()
        ))

        let fpStart = CFAbsoluteTimeGetCurrent()
        var fpSum: Double = 0
        for i in 0..<iterations {
            fpSum += Double(i) * Double(i)
        }
        let fpElapsed = CFAbsoluteTimeGetCurrent() - fpStart
        let fpOpsPerSec = Double(iterations) / fpElapsed
        results.append(BenchmarkResult(
            name: "CPU Float Ops",
            value: fpOpsPerSec / 1_000_000_000,
            unit: "G ops/sec",
            timestamp: Date()
        ))

        let simdStart = CFAbsoluteTimeGetCurrent()
        var simdSum: SIMD4<Float> = .zero
        for i in 0..<(iterations / 4) {
            let val = SIMD4<Float>(Float(i), Float(i), Float(i), Float(i))
            simdSum = simdSum + val
        }
        let simdElapsed = CFAbsoluteTimeGetCurrent() - simdStart
        let simdOpsPerSec = Double(iterations) / simdElapsed
        results.append(BenchmarkResult(
            name: "CPU SIMD Ops",
            value: simdOpsPerSec / 1_000_000_000,
            unit: "G ops/sec",
            timestamp: Date()
        ))
    }

    private func runMemoryBenchmarks() async {
        let sizes = [1 << 20, 1 << 24, 1 << 26] // 1MB, 16MB, 64MB

        for size in sizes {
            let buffer = UnsafeMutableBufferPointer<UInt64>.allocate(capacity: size / 8)
            defer { buffer.deallocate() }

            let iterations = 1_000
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                for i in buffer.indices {
                    let current = buffer[i]
                    buffer[i] = current &+ 1
                }
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let bytesProcessed = UInt64(buffer.count) * 8 * UInt64(iterations)
            let gbPerSec = Double(bytesProcessed) / elapsed / 1_000_000_000
            let mbSuffix = size / (1 << 20)

            results.append(BenchmarkResult(
                name: "Memory BW (\(mbSuffix)MB)",
                value: gbPerSec,
                unit: "GB/sec",
                timestamp: Date()
            ))
        }
    }

    private func runGPUBenchmarks(device: MTLDevice) async {
        guard let commandQueue = device.makeCommandQueue() else { return }

        let bufferSize = 1024 * 1024
        guard let buffer = device.makeBuffer(length: bufferSize, options: .storageModeShared) else { return }

        let start = CFAbsoluteTimeGetCurrent()
        let iterations = 10_000

        for _ in 0..<iterations {
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { continue }
            guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { continue }

            blitEncoder.fill(buffer: buffer, range: 0..<bufferSize, value: 42)
            blitEncoder.endEncoding()

            commandBuffer.commit()
            // Avoid waitUntilCompleted in async context
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let commandsPerSec = Double(iterations) / elapsed

        results.append(BenchmarkResult(
            name: "GPU Blit Commands",
            value: commandsPerSec,
            unit: "cmds/sec",
            timestamp: Date()
        ))
    }
}
