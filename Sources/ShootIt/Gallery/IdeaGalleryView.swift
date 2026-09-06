import SwiftUI

struct IdeaGalleryActions {
    let preview: (IdeaItem) -> Void
    let copy: (IdeaItem) -> Void
    let reveal: (IdeaItem) -> Void
    let delete: (IdeaItem) -> Void
}

struct IdeaGalleryView: View {
    @ObservedObject var store: IdeaGalleryStore
    let actions: IdeaGalleryActions

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 260), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            if store.visibleItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.visibleItems) { item in
                            card(for: item)
                        }
                    }
                    .padding(20)
                }
            }
            Divider()
            footer
        }
        .frame(minWidth: 700, minHeight: 480)
        .searchable(text: $store.query, prompt: "Dateiname oder Datum")
        .alert("Galerie konnte nicht geladen werden", isPresented: errorIsPresented) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "Unbekannter Fehler")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label(store.query.isEmpty ? "Noch keine Ideen" : "Keine Treffer", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text(store.query.isEmpty ? "Archivierte PNG-Dateien erscheinen hier automatisch." : "Suche nach Dateiname oder Aufnahmedatum.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func card(for item: IdeaItem) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            GalleryThumbnailView(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 10, contentMode: .fit)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(item.filename)
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
            Text(item.captureDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(store.selectedID == item.id ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(store.selectedID == item.id ? Color.accentColor : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { actions.preview(item) }
        .onTapGesture { store.selectedID = item.id }
        .contextMenu {
            Button("In Vorschau öffnen") { actions.preview(item) }
            Button("Kopieren") { actions.copy(item) }
            Button("Im Finder anzeigen") { actions.reveal(item) }
            Divider()
            Button("Löschen …", role: .destructive) { actions.delete(item) }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(store.visibleItems.count) \(store.visibleItems.count == 1 ? "Idee" : "Ideen")")
                .foregroundStyle(.secondary)
            Spacer()
            if let item = store.selectedItem {
                Button("Vorschau") { actions.preview(item) }
                Button("Kopieren") { actions.copy(item) }
                Button("Im Finder") { actions.reveal(item) }
                Button("Löschen …", role: .destructive) { actions.delete(item) }
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
    }
}

private struct GalleryThumbnailView: View {
    let item: IdeaItem
    @State private var image: CGImage?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
            } else if !didLoad {
                ProgressView()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: ThumbnailCacheKey.make(for: item, maxPixelSize: 512)) {
            image = nil
            didLoad = false
            image = await ThumbnailCache.shared.image(for: item, maxPixelSize: 512)
            didLoad = true
        }
    }
}
