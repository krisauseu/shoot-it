import Foundation

struct IdeaItem: Identifiable, Equatable, Sendable {
    let url: URL
    let filename: String
    let captureDate: Date
    let modificationDate: Date
    let fileSize: Int64

    var id: String { url.standardizedFileURL.path }

    var dateSearchText: String {
        let components = Calendar.autoupdatingCurrent.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: captureDate
        )
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute else { return "" }
        let numeric = String(
            format: "%02d.%02d.%04d %02d:%02d %04d-%02d-%02d %02d:%02d",
            day, month, year, hour, minute, year, month, day, hour, minute
        )
        return numeric + " " + captureDate.formatted(date: .abbreviated, time: .shortened)
    }
}

enum IdeaGalleryCatalog {
    static func load(from directory: URL, fileManager: FileManager = .default) throws -> [IdeaItem] {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .creationDateKey, .contentModificationDateKey, .fileSizeKey]
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        )
        let items = try urls.compactMap { url -> IdeaItem? in
            guard url.pathExtension.caseInsensitiveCompare("png") == .orderedSame else { return nil }
            let values = try url.resourceValues(forKeys: keys)
            guard values.isRegularFile == true else { return nil }
            let modificationDate = values.contentModificationDate ?? .distantPast
            return IdeaItem(
                url: url,
                filename: url.lastPathComponent,
                captureDate: captureDate(fromFilename: url.deletingPathExtension().lastPathComponent)
                    ?? values.creationDate
                    ?? modificationDate,
                modificationDate: modificationDate,
                fileSize: Int64(values.fileSize ?? 0)
            )
        }
        return sorted(items)
    }

    private static func captureDate(fromFilename filename: String) -> Date? {
        guard filename.count >= 19 else { return nil }
        let timestamp = String(filename.prefix(19))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.date(from: timestamp)
    }

    static func filtered(_ items: [IdeaItem], query: String) -> [IdeaItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return sorted(items) }
        return sorted(items.filter { item in
            item.filename.localizedCaseInsensitiveContains(needle)
                || item.dateSearchText.localizedCaseInsensitiveContains(needle)
        })
    }

    static func sorted(_ items: [IdeaItem]) -> [IdeaItem] {
        items.sorted {
            if $0.captureDate != $1.captureDate { return $0.captureDate > $1.captureDate }
            return $0.filename.localizedStandardCompare($1.filename) == .orderedAscending
        }
    }
}
