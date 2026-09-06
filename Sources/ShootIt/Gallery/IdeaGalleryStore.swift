import Combine
import Foundation

@MainActor
final class IdeaGalleryStore: ObservableObject {
    @Published private(set) var items: [IdeaItem] = []
    @Published private(set) var visibleItems: [IdeaItem] = []
    @Published private(set) var isLoading = false
    @Published var query = "" { didSet { applyFilter() } }
    @Published var selectedID: IdeaItem.ID?
    @Published var errorMessage: String?

    private let preferences: Preferences
    private let monitor = IdeaFolderMonitor()
    private var cancellables: Set<AnyCancellable> = []
    private var loadTask: Task<Void, Never>?

    init(preferences: Preferences) {
        self.preferences = preferences
        preferences.$ideaFolderURL
            .removeDuplicates()
            .sink { [weak self] directory in self?.use(directory: directory) }
            .store(in: &cancellables)
    }

    var selectedItem: IdeaItem? {
        guard let selectedID else { return nil }
        return items.first(where: { $0.id == selectedID })
    }

    func reload() {
        let directory = preferences.ideaFolderURL
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            let result = await Task.detached(priority: .utility) {
                Result { try IdeaGalleryCatalog.load(from: directory) }
            }.value
            guard !Task.isCancelled, let self else { return }
            isLoading = false
            switch result {
            case let .success(loaded):
                items = loaded
                if let selectedID, !loaded.contains(where: { $0.id == selectedID }) {
                    self.selectedID = nil
                }
                applyFilter()
                errorMessage = nil
            case let .failure(error):
                items = []
                visibleItems = []
                errorMessage = error.localizedDescription
            }
        }
    }

    private func use(directory: URL) {
        loadTask?.cancel()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        monitor.start(directory: directory) { [weak self] in self?.reload() }
        Task { await ThumbnailCache.shared.removeAll() }
        reload()
    }

    private func applyFilter() {
        visibleItems = IdeaGalleryCatalog.filtered(items, query: query)
        if let selectedID, !visibleItems.contains(where: { $0.id == selectedID }) {
            self.selectedID = nil
        }
    }
}
