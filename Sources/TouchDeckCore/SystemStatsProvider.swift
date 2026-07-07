import AppKit
import Darwin
import Foundation
import IOKit.ps

public struct MemoryStats: Codable, Equatable, Sendable {
    public var usedBytes: UInt64
    public var totalBytes: UInt64

    public init(usedBytes: UInt64, totalBytes: UInt64) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
    }

    public var usedRatio: Double {
        guard totalBytes > 0 else {
            return 0
        }

        return min(Double(usedBytes) / Double(totalBytes), 1)
    }
}

public struct DiskStats: Codable, Equatable, Sendable {
    public var usedBytes: UInt64
    public var totalBytes: UInt64

    public init(usedBytes: UInt64, totalBytes: UInt64) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
    }

    public var usedRatio: Double {
        guard totalBytes > 0 else {
            return 0
        }

        return min(Double(usedBytes) / Double(totalBytes), 1)
    }
}

public struct BatteryStats: Codable, Equatable, Sendable {
    public var percentage: Int
    public var isCharging: Bool

    public init(percentage: Int, isCharging: Bool) {
        self.percentage = min(max(percentage, 0), 100)
        self.isCharging = isCharging
    }

    public var usedRatio: Double {
        Double(percentage) / 100
    }
}

public struct CPULoadStats: Codable, Equatable, Sendable {
    public var loadAverage: Double
    public var coreCount: Int

    public init(loadAverage: Double, coreCount: Int) {
        self.loadAverage = max(loadAverage, 0)
        self.coreCount = max(coreCount, 1)
    }

    public var loadRatio: Double {
        min(loadAverage / Double(coreCount), 1)
    }
}

public struct SystemStatsProvider: Sendable {
    public init() {}

    public func memoryStats() -> MemoryStats {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let hostPort = mach_host_self()
        var pageSize: vm_size_t = 0
        host_page_size(hostPort, &pageSize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(hostPort, HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryStats(usedBytes: 0, totalBytes: totalBytes)
        }

        let usedPages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)
        let usedBytes = usedPages * UInt64(pageSize)

        return MemoryStats(usedBytes: min(usedBytes, totalBytes), totalBytes: totalBytes)
    }

    public func diskStats(for url: URL = URL(fileURLWithPath: "/")) -> DiskStats? {
        guard
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: url.path),
            let totalSize = attributes[.systemSize] as? NSNumber,
            let freeSize = attributes[.systemFreeSize] as? NSNumber
        else {
            return nil
        }

        let totalBytes = totalSize.uint64Value
        let freeBytes = freeSize.uint64Value
        let usedBytes = totalBytes > freeBytes ? totalBytes - freeBytes : 0

        return DiskStats(usedBytes: usedBytes, totalBytes: totalBytes)
    }

    public func batteryStats() -> BatteryStats? {
        guard
            let powerSourceInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let powerSources = IOPSCopyPowerSourcesList(powerSourceInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for powerSource in powerSources {
            guard
                let description = IOPSGetPowerSourceDescription(powerSourceInfo, powerSource)?
                    .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                maxCapacity > 0
            else {
                continue
            }

            let powerState = description[kIOPSPowerSourceStateKey] as? String
            let isCharging = powerState == kIOPSACPowerValue
            let percentage = Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())

            return BatteryStats(percentage: percentage, isCharging: isCharging)
        }

        return nil
    }

    public func cpuLoadStats() -> CPULoadStats {
        var loads = [Double](repeating: 0, count: 3)
        let sampleCount = getloadavg(&loads, Int32(loads.count))
        let loadAverage = sampleCount > 0 ? loads[0] : 0
        return CPULoadStats(
            loadAverage: loadAverage,
            coreCount: ProcessInfo.processInfo.processorCount
        )
    }

    public func snapshot(for widgetId: String, date: Date = Date()) -> WidgetSnapshot? {
        switch widgetId {
        case "system.ram":
            let stats = memoryStats()
            return WidgetSnapshot(
                title: "RAM \(Self.percentString(stats.usedRatio))",
                subtitle: Self.byteString(stats.usedBytes),
                symbolName: "memorychip",
                progress: stats.usedRatio,
                colorHex: "#0A84FF"
            )
        case "system.ssd":
            guard let stats = diskStats() else {
                return nil
            }

            return WidgetSnapshot(
                title: "SSD \(Self.percentString(stats.usedRatio))",
                subtitle: Self.byteString(stats.usedBytes),
                symbolName: "internaldrive",
                progress: stats.usedRatio,
                colorHex: "#30D158"
            )
        case "system.cpu":
            let stats = cpuLoadStats()
            return WidgetSnapshot(
                title: "CPU \(Self.percentString(stats.loadRatio))",
                subtitle: String(format: "Load %.2f", stats.loadAverage),
                symbolName: "cpu",
                progress: stats.loadRatio,
                colorHex: "#FF9F0A"
            )
        case "system.battery":
            guard let stats = batteryStats() else {
                return nil
            }

            return WidgetSnapshot(
                title: "BAT \(stats.percentage)%",
                subtitle: stats.isCharging ? "Charging" : "Battery",
                symbolName: stats.isCharging ? "battery.100.bolt" : "battery.100",
                progress: stats.usedRatio,
                colorHex: "#FFD60A"
            )
        case "system.clock":
            return WidgetSnapshot(
                title: Self.timeString(date),
                subtitle: Self.dateString(date),
                symbolName: "clock",
                progress: nil,
                colorHex: "#BF5AF2"
            )
        case "system.activeApp":
            let app = NSWorkspace.shared.frontmostApplication
            return WidgetSnapshot(
                title: app?.localizedName ?? "Active App",
                subtitle: app?.bundleIdentifier,
                symbolName: "app.badge",
                progress: nil,
                colorHex: "#5E5CE6"
            )
        case "weather.current":
            return WidgetSnapshot(
                title: "Weather",
                subtitle: "Provider not configured",
                symbolName: "cloud.sun",
                progress: nil,
                colorHex: "#64D2FF"
            )
        default:
            return nil
        }
    }

    public static func percentString(_ ratio: Double) -> String {
        let clampedRatio = min(max(ratio, 0), 1)
        return "\(Int((clampedRatio * 100).rounded()))%"
    }

    public static func byteString(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    public static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    public static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
