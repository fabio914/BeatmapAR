import XCTest
@testable import BeatmapLoader

final class TestLoaderDataSource: BeatmapLoaderDataSourceProtocol {

    func loader(_ loader: BeatmapLoader, dataForFileNamed fileName: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        let fileComponents = fileName.split(separator: ".")
        let resource = String(fileComponents.dropLast().joined())

        guard let type = fileComponents.last,
            let url = bundle.url(forResource: resource, withExtension: String(type))
        else {
            return nil
        }

        return try? Data(contentsOf: url)
    }
}

final class LoaderTests: XCTestCase {
    let dataSource = TestLoaderDataSource()
    lazy var loader = BeatmapLoader(dataSource: dataSource)

    func testLoadSong() {
        let map = try? loader.loadMap()
        XCTAssertNotNil(map)
        XCTAssertEqual(map?.songName, "Test Song Name")
        XCTAssertEqual(map?.songSubName, "Test Song SubName")
        XCTAssertEqual(map?.songAuthorName, "Test Artist")
        XCTAssertEqual(map?.levelAuthorName, "Test Mapper")
        XCTAssertEqual(map?.beatsPerMinute, 120)
        XCTAssertEqual(map?.songTimeOffset, 0)

        XCTAssertEqual(map?.difficulties.count, 2)
        XCTAssertEqual(map?.difficulties[0].difficulty, .normal)
        XCTAssertEqual(map?.difficulties[1].difficulty, .expert)
    }
}
