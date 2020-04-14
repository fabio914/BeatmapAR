import Foundation

public protocol BeatmapLoaderDataSourceProtocol: AnyObject {
    func loader(_ loader: BeatmapLoader, dataForFileNamed fileName: String) -> Data?
}

public enum BeatmapLoaderError: Error {
    case unableToLoadBeatmapInfo
    case unableToLoadCoverImage
    case standardBeatmapMissing
    case unableToLoadMapDifficulty(_ named: String)
}

public final class BeatmapLoader {
    private weak var dataSource: BeatmapLoaderDataSourceProtocol?

    private let beatmapInfoFileName = "info.dat"

    public init(dataSource: BeatmapLoaderDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func loadMap() throws -> BeatmapSong {

        guard let infoData = dataSource?.loader(self, dataForFileNamed: beatmapInfoFileName),
            let info = try? JSONDecoder().decode(BeatmapInfoModel.self, from: infoData)
        else {
            throw BeatmapLoaderError.unableToLoadBeatmapInfo
        }

        guard let coverImageData = dataSource?.loader(self, dataForFileNamed: info.coverImageFilename),
            let coverImage = UIImage(data: coverImageData)
        else {
            throw BeatmapLoaderError.unableToLoadCoverImage
        }

        guard let standardBeatmap = info.difficultyBeatmapSets.first else {
            throw BeatmapLoaderError.standardBeatmapMissing
        }

        return .init(
            songName: info.songName,
            songSubName: info.songSubName,
            songAuthorName: info.songAuthorName,
            levelAuthorName: info.levelAuthorName,
            beatsPerMinute: info.beatsPerMinute,
            songTimeOffset: info.songTimeOffset,
            coverImage: coverImage,
            difficulties: try standardBeatmap.difficultyBeatmaps.map({ beatmap in
                guard let mapData = dataSource?.loader(self, dataForFileNamed: beatmap.beatmapFilename),
                    let map = try? JSONDecoder().decode(BeatmapDifficultyModel.self, from: mapData)
                else {
                    throw BeatmapLoaderError.unableToLoadMapDifficulty(beatmap.beatmapFilename)
                }

                return .init(
                    difficulty: beatmap.difficultyRank.difficulty
                )
            })
        )
    }
}
