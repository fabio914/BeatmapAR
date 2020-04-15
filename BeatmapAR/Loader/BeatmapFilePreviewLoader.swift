import Foundation
import BeatmapLoader

final class BeatmapFilePreviewLoader {

    let directoryURL: URL
    private let zipExtension = "zip"

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    init?() {
        let manager = FileManager.default
        guard let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        self.directoryURL = documentsURL
    }

    func loadFilePreviews() -> [BeatmapFilePreview] {
        // TODO: Move this to a background thread and load this asynchronously.

        let manager = FileManager.default
        guard let contents = try? manager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents
            .filter({ $0.pathExtension == zipExtension })
            .compactMap({ url in
                let zipDataSource = ZIPBeatmapLoaderDataSource(with: url)
                let loader = BeatmapLoader(dataSource: zipDataSource)
                guard let preview = try? loader.loadPreview() else { return nil }
                return .init(preview: preview, url: url)
            })
    }
}
