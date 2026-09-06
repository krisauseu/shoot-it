import Foundation
import Testing
@testable import ShootIt

struct IdeaGalleryCatalogTests {
    @Test func catalogReadsPlainPNGsWithoutSidecars() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let png = directory.appendingPathComponent("2026-09-06_09-15-32.PNG")
        try Data([0x89, 0x50, 0x4e, 0x47]).write(to: png)
        try Data("ignore".utf8).write(to: directory.appendingPathComponent("note.txt"))

        let loaded = try IdeaGalleryCatalog.load(from: directory)

        #expect(loaded.map(\.filename) == ["2026-09-06_09-15-32.PNG"])
        let calendar = Calendar(identifier: .gregorian)
        #expect(calendar.component(.year, from: loaded[0].captureDate) == 2026)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).count == 2)
    }

    @Test func sortingUsesNewestCaptureFirstAndFilenameAsTieBreaker() {
        let early = Date(timeIntervalSinceReferenceDate: 100)
        let late = Date(timeIntervalSinceReferenceDate: 200)
        let items = [
            item("z.png", date: early),
            item("b.png", date: late),
            item("a.png", date: late)
        ]

        let sorted = IdeaGalleryCatalog.sorted(items)

        #expect(sorted.map(\.filename) == ["a.png", "b.png", "z.png"])
    }

    @Test func filteringMatchesFilenameAndCommonDateFormats() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 9, minute: 15))!
        let items = [item("Launch-Idee.PNG", date: date), item("anderes.png", date: .distantPast)]

        #expect(IdeaGalleryCatalog.filtered(items, query: "launch").map(\.filename) == ["Launch-Idee.PNG"])
        #expect(IdeaGalleryCatalog.filtered(items, query: "06.09.2026").map(\.filename) == ["Launch-Idee.PNG"])
        #expect(IdeaGalleryCatalog.filtered(items, query: "2026-09-06").map(\.filename) == ["Launch-Idee.PNG"])
    }

    private func item(_ filename: String, date: Date) -> IdeaItem {
        IdeaItem(
            url: URL(fileURLWithPath: "/tmp/\(filename)"),
            filename: filename,
            captureDate: date,
            modificationDate: date,
            fileSize: 10
        )
    }
}
