import UIKit
import BeatmapLoader
import APAudioPlayer

final class SongViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var coverImageView: UIImageView!
    @IBOutlet private weak var songNameLabel: UILabel!
    @IBOutlet private weak var songSubNameLabel: UILabel!
    @IBOutlet private weak var songArtistLabel: UILabel!
    @IBOutlet private weak var bpmLabel: UILabel!
    @IBOutlet private weak var mapperLabel: UILabel!

    private let filePreview: BeatmapFilePreview
    private let audioPlayer = APAudioPlayer()

    init(filePreview: BeatmapFilePreview) {
        self.filePreview = filePreview
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // This is a test...

        let zipDataSource = ZIPBeatmapLoaderDataSource(with: filePreview.url)
        let loader = BeatmapLoader(dataSource: zipDataSource)

        guard let map = try? loader.loadMap() else {
            // TODO: Show error alert and dismiss
            stackView.isHidden = true
            return
        }

        let manager = FileManager.default
        let destinationURL = manager.temporaryDirectory.appendingPathComponent("song.ogg")

        do {
            try map.song.write(to: destinationURL)
            audioPlayer.loadItem(with: destinationURL, autoPlay: true)
        } catch {
            // TODO: Do something
        }

        let preview = filePreview.preview
        coverImageView.image = preview.coverImage

        let songName = preview.songName.trimmingCharacters(in: .whitespacesAndNewlines)
        let songSubName = preview.songSubName.trimmingCharacters(in: .whitespacesAndNewlines)
        let songArtist = preview.songAuthorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mapper = preview.levelAuthorName.trimmingCharacters(in: .whitespacesAndNewlines)

        songNameLabel.text = songName
        songNameLabel.isHidden = songName.isEmpty

        songSubNameLabel.text = songSubName
        songSubNameLabel.isHidden = songSubName.isEmpty

        songArtistLabel.text = songArtist
        songArtistLabel.isHidden = songArtist.isEmpty

        mapperLabel.text = mapper
        mapperLabel.isHidden = mapper.isEmpty

        bpmLabel.text = "\(preview.beatsPerMinute)"
    }

    // MARK: - Actions

    @IBAction private func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
