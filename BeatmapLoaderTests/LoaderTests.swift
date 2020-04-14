import XCTest
@testable import BeatmapLoader
import ZIPFoundation

final class TestLoaderDataSource: BeatmapLoaderDataSourceProtocol {

    private let zipFileName: String

    private lazy var archive: Archive? = {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: zipFileName, withExtension: "zip") else {
            return nil
        }
        return Archive(url: url, accessMode: .read)
    }()

    init(zipFileName: String) {
        self.zipFileName = zipFileName
    }

    func loader(_ loader: BeatmapLoader, dataForFileNamed fileName: String) -> Data? {
        var result = Data()

        guard let entry = archive?[fileName],
            let _ = try? archive?.extract(entry, consumer: { chunk in result.append(chunk) })
        else {
            return nil
        }

        return result
    }
}

final class LoaderTests: XCTestCase {
    let dataSource = TestLoaderDataSource(zipFileName: "TestSong")
    lazy var loader = BeatmapLoader(dataSource: dataSource)

    func testLoadSong() {
        let map: BeatmapSong! = try? loader.loadMap()
        XCTAssertNotNil(map)
        XCTAssertEqual(map.songName, "Test Song Name")
        XCTAssertEqual(map.songSubName, "Test Song SubName")
        XCTAssertEqual(map.songAuthorName, "Test Artist")
        XCTAssertEqual(map.levelAuthorName, "Test Mapper")
        XCTAssertEqual(map.beatsPerMinute, 120)

        XCTAssertEqual(map.difficulties.count, 2)
        XCTAssertEqual(map.difficulties[0].difficulty, .normal)
        XCTAssertEqual(map.difficulties[1].difficulty, .expert)

        let normalMap = map.difficulties[0]
        XCTAssertEqual(normalMap.bombCount, 2)
        XCTAssertEqual(normalMap.noteCount, 32)
        XCTAssertEqual(normalMap.duration, 5.5)
        XCTAssertEqual(floor(normalMap.notesPerSecond), 5) // TODO: Check this value
    }
}
