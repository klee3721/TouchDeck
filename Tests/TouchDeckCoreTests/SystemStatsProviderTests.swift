import Foundation
import Testing
import TouchDeckCore

@Test func memoryStatsReturnsPositiveTotalMemory() {
    let stats = SystemStatsProvider().memoryStats()

    #expect(stats.totalBytes > 0)
    #expect(stats.usedBytes <= stats.totalBytes)
    #expect(stats.usedRatio >= 0)
    #expect(stats.usedRatio <= 1)
}

@Test func diskStatsReturnsPositiveRootVolumeSize() throws {
    let stats = try #require(SystemStatsProvider().diskStats())

    #expect(stats.totalBytes > 0)
    #expect(stats.usedBytes <= stats.totalBytes)
    #expect(stats.usedRatio >= 0)
    #expect(stats.usedRatio <= 1)
}

@Test func systemWidgetSnapshotsIncludeReadableTitles() throws {
    let provider = SystemStatsProvider()
    let ramSnapshot = try #require(provider.snapshot(for: "system.ram"))
    let ssdSnapshot = try #require(provider.snapshot(for: "system.ssd"))
    let cpuSnapshot = try #require(provider.snapshot(for: "system.cpu"))
    let clockSnapshot = try #require(provider.snapshot(for: "system.clock", date: Date(timeIntervalSince1970: 0)))
    let activeAppSnapshot = try #require(provider.snapshot(for: "system.activeApp"))
    let weatherSnapshot = try #require(provider.snapshot(for: "weather.current"))

    #expect(ramSnapshot.title.hasPrefix("RAM "))
    #expect(ssdSnapshot.title.hasPrefix("SSD "))
    #expect(cpuSnapshot.title.hasPrefix("CPU "))
    #expect(weatherSnapshot.title == "Weather")
    #expect(clockSnapshot.title.count == 5)
    #expect(clockSnapshot.title.contains(":"))
    #expect(activeAppSnapshot.title.isEmpty == false)
    #expect(ramSnapshot.progress != nil)
    #expect(ssdSnapshot.progress != nil)
    #expect(cpuSnapshot.progress != nil)
}

@Test func cpuLoadStatsReturnsClampedProgress() {
    let stats = SystemStatsProvider().cpuLoadStats()

    #expect(stats.coreCount > 0)
    #expect(stats.loadAverage >= 0)
    #expect(stats.loadRatio >= 0)
    #expect(stats.loadRatio <= 1)
}

@Test func clockSnapshotHasStableFormattedDate() throws {
    let snapshot = try #require(
        SystemStatsProvider().snapshot(
            for: "system.clock",
            date: Date(timeIntervalSince1970: 0)
        )
    )

    #expect(snapshot.symbolName == "clock")
    #expect(snapshot.subtitle?.isEmpty == false)
}

@Test func percentStringClampsRatio() {
    #expect(SystemStatsProvider.percentString(-1) == "0%")
    #expect(SystemStatsProvider.percentString(0.424) == "42%")
    #expect(SystemStatsProvider.percentString(2) == "100%")
}
