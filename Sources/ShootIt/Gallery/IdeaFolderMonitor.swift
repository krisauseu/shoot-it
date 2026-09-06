import Darwin
import Foundation

final class IdeaFolderMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1

    func start(directory: URL, onChange: @escaping () -> Void) {
        stop()
        descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .attrib, .extend],
            queue: .main
        )
        source.setEventHandler(handler: onChange)
        source.setCancelHandler { [descriptor] in close(descriptor) }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
        descriptor = -1
    }

    deinit {
        stop()
    }
}
