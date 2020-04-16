import Foundation

public protocol BeatmapLoaderDataSourceProtocol: AnyObject {
    func loader(_ loader: BeatmapLoader, dataForFileNamed fileName: String) -> Data?
}

public enum BeatmapLoaderError: Error {
    case unableToLoadBeatmapInfo
    case unableToLoadCoverImage
    case unableToLoadSongFile
    case standardBeatmapMissing
    case unableToLoadMapDifficulty(_ named: String)
}

public final class BeatmapLoader {
    private weak var dataSource: BeatmapLoaderDataSourceProtocol?

    private let beatmapInfoFileName = "info.dat"
    private let alternativeBeatmapInfoFileName = "Info.dat"

    public init(dataSource: BeatmapLoaderDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func loadPreview() throws -> BeatmapPreview {
        try preview(from: try loadInfo())
    }

    public func loadMap() throws -> BeatmapSong {

        let info = try loadInfo()
        let preview = try self.preview(from: info)

        guard let song = dataSource?.loader(self, dataForFileNamed: info.songFilename) else {
            throw BeatmapLoaderError.unableToLoadSongFile
        }

        guard let standardBeatmap = info.difficultyBeatmapSets
            .first(where: { $0.beatmapCharacteristicName == .standard })
        else {
            throw BeatmapLoaderError.standardBeatmapMissing
        }

        let sortedStandardBeatmaps = standardBeatmap.difficultyBeatmaps
            .sorted(by: { $0.difficultyRank < $1.difficultyRank })

        let standardDifficulties = try sortedStandardBeatmaps
            .map({ beatmap -> BeatmapSongDifficulty in
                guard let mapData = dataSource?.loader(self, dataForFileNamed: beatmap.beatmapFilename),
                    let map = try? JSONDecoder().decode(BeatmapDifficultyModel.self, from: mapData)
                else {
                    throw BeatmapLoaderError.unableToLoadMapDifficulty(beatmap.beatmapFilename)
                }

                return .init(
                    difficulty: beatmap.difficultyRank.difficulty,
                    notes: map.notes
                        .sorted(by: { $0.time < $1.time })
                        .map({ $0.asNoteEvent(with: info.beatsPerMinute, offset: info.songTimeOffset) })
                )
            })

        return .init(preview: preview, song: song, standardDifficulties: standardDifficulties)
    }

    // MARK: - Private

    private func loadInfo() throws -> BeatmapInfoModel {

        guard
            let infoData =
                dataSource?.loader(self, dataForFileNamed: beatmapInfoFileName) ??
                dataSource?.loader(self, dataForFileNamed: alternativeBeatmapInfoFileName),
            let info = try? JSONDecoder().decode(BeatmapInfoModel.self, from: infoData)
        else {
            throw BeatmapLoaderError.unableToLoadBeatmapInfo
        }

        return info
    }

    private func preview(from info: BeatmapInfoModel) throws -> BeatmapPreview {

        guard let coverImageData = dataSource?.loader(self, dataForFileNamed: info.coverImageFilename),
            let coverImage = UIImage(data: coverImageData)
        else {
            throw BeatmapLoaderError.unableToLoadCoverImage
        }

        return .init(
            songName: info.songName,
            songSubName: info.songSubName,
            songAuthorName: info.songAuthorName,
            levelAuthorName: info.levelAuthorName,
            beatsPerMinute: info.beatsPerMinute,
            coverImage: coverImage
        )
    }
}
