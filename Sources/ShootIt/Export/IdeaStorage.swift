import Foundation

enum IdeaStorage {
    static func save(_ document: ScreenshotDocument, to directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let baseName = filenameFormatter.string(from: document.createdAt)
        let imageURL = availableURL(in: directory, baseName: baseName, extension: "png")

        try DocumentRenderer.pngData(document).write(to: imageURL, options: .atomic)
        return imageURL
    }

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    private static func availableURL(in directory: URL, baseName: String, extension pathExtension: String) -> URL {
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension(pathExtension)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName)_\(suffix)").appendingPathExtension(pathExtension)
            suffix += 1
        }
        return candidate
    }
}
