import Foundation
import Metal

enum PerformanceTier: Int, Comparable, Codable {
    case low = 0
    case medium = 1
    case high = 2
    case ultra = 3

    static func < (a: PerformanceTier, b: PerformanceTier) -> Bool { a.rawValue < b.rawValue }

    var name: String {
        switch self {
        case .low: return "Low (A8–A10)"
        case .medium: return "Medium (A11–A13)"
        case .high: return "High (A14–A17/M1)"
        case .ultra: return "Ultra (M2–M4)"
        }
    }
}

struct DeviceProfile {
    let tier: PerformanceTier
    let gpuName: String
    let gpuFamily: String
    let supportsNonUniformThreadgroups: Bool
    let maxThreadsPerThreadgroup: Int
    let recommendedWorkingSetBytes: UInt64
    let physicalMemoryBytes: UInt64
    let processorCount: Int

    var benchmarkIterations: Int {
        switch tier {
        case .low: return 1_000_000
        case .medium: return 5_000_000
        case .high: return 20_000_000
        case .ultra: return 50_000_000
        }
    }

    static func detect(device: MTLDevice? = MTLCreateSystemDefaultDevice()) -> DeviceProfile {
        guard let device else {
            return fallback()
        }

        let ram = ProcessInfo.processInfo.physicalMemory
        let workingSet = device.recommendedMaxWorkingSetSize
        let procCount = ProcessInfo.processInfo.activeProcessorCount

        var tier: PerformanceTier
        var gpuFamily = "Unknown"

        if #available(iOS 17, *) {
            if device.supportsFamily(.apple9) {
                tier = .ultra
                gpuFamily = "Apple9 (M4)"
            } else if device.supportsFamily(.apple8), ram >= (8 << 30) {
                tier = .ultra
                gpuFamily = "Apple8 (M2–M3)"
            } else if device.supportsFamily(.apple7) {
                tier = .high
                gpuFamily = "Apple7 (A14–M1)"
            } else if device.supportsFamily(.apple6) {
                tier = .medium
                gpuFamily = "Apple6 (A12Z)"
            } else {
                tier = .low
                gpuFamily = "Apple5 or earlier"
            }
        } else if #available(iOS 16, *) {
            if device.supportsFamily(.apple8), ram >= (8 << 30) {
                tier = .ultra
                gpuFamily = "Apple8 (M2–M3)"
            } else if device.supportsFamily(.apple7) {
                tier = .high
                gpuFamily = "Apple7 (A14–M1)"
            } else if device.supportsFamily(.apple6) {
                tier = .medium
                gpuFamily = "Apple6 (A12Z)"
            } else if device.supportsFamily(.apple4) {
                tier = .medium
                gpuFamily = "Apple4–5"
            } else {
                tier = .low
                gpuFamily = "Apple3 or earlier"
            }
        } else {
            tier = .low
            gpuFamily = "Unknown (pre-iOS 16)"
        }

        let nonUniform = device.supportsFamily(.apple4)

        return DeviceProfile(
            tier: tier,
            gpuName: device.name,
            gpuFamily: gpuFamily,
            supportsNonUniformThreadgroups: nonUniform,
            maxThreadsPerThreadgroup: device.maxThreadsPerThreadgroup.width,
            recommendedWorkingSetBytes: workingSet == 0 ? (ram / 2) : workingSet,
            physicalMemoryBytes: ram,
            processorCount: procCount
        )
    }

    private static func fallback() -> DeviceProfile {
        DeviceProfile(
            tier: .low,
            gpuName: "none",
            gpuFamily: "Unknown",
            supportsNonUniformThreadgroups: false,
            maxThreadsPerThreadgroup: 256,
            recommendedWorkingSetBytes: 256 << 20,
            physicalMemoryBytes: 1 << 30,
            processorCount: 1
        )
    }
}
