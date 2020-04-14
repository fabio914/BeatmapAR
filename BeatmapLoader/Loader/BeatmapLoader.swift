import Foundation

public protocol BeatmapLoaderDataSourceProtocol: AnyObject {
    func loader(_ loader: BeatmapLoader, dataForFileNamed fileName: String) -> Data?
}

public enum BeatmapLoaderError: Error {
    case unableToLoadBeatmapInfo
}

public final class BeatmapLoader {
    private weak var dataSource: BeatmapLoaderDataSourceProtocol?

    private let beatmapInfoFileName = "info.dat"

    public init(dataSource: BeatmapLoaderDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func loadMap() throws -> Beatmap {

        guard let infoData = dataSource?.loader(self, dataForFileNamed: beatmapInfoFileName),
            let info = try? JSONDecoder().decode(BeatmapInfoModel.self, from: infoData)
        else {
            throw BeatmapLoaderError.unableToLoadBeatmapInfo
        }

        return .init(
            songName: info.songName
        )
    }
}
