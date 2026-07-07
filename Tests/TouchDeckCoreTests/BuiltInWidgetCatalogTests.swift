import Testing
import TouchDeckCore

@Test func builtInWidgetCatalogIDsAreUnique() {
    let ids = BuiltInWidgetCatalog.all.map(\.id)

    #expect(Set(ids).count == ids.count)
}

@Test func builtInWidgetCatalogFindsKnownWidgets() throws {
    let ram = try #require(BuiltInWidgetCatalog.definition(id: "system.ram"))
    let ssd = try #require(BuiltInWidgetCatalog.definition(id: "system.ssd"))
    let cpu = try #require(BuiltInWidgetCatalog.definition(id: "system.cpu"))
    let battery = try #require(BuiltInWidgetCatalog.definition(id: "system.battery"))
    let activeApp = try #require(BuiltInWidgetCatalog.definition(id: "system.activeApp"))
    let weather = try #require(BuiltInWidgetCatalog.definition(id: "weather.current"))

    #expect(ram.name == "RAM")
    #expect(ram.refreshIntervalSeconds == 5)
    #expect(ram.supportedSizes == [.small])
    #expect(ssd.supportedSizes == [.small])
    #expect(cpu.name == "CPU Load")
    #expect(cpu.refreshIntervalSeconds == 5)
    #expect(cpu.supportedSizes == [.small])
    #expect(battery.supportedSizes == [.small])
    #expect(activeApp.supportedSizes == [.small])
    #expect(weather.supportedSizes == [.small])
    #expect(weather.parameters.map(\.id) == ["location"])
    #expect(weather.parameters[0].kind == .location)
}
