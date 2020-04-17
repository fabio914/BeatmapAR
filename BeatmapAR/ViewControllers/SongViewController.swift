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
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var mapperLabel: UILabel!
    @IBOutlet private weak var standardModeViewContainer: UIView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var notesPerSecondLabel: UILabel!
    @IBOutlet private weak var notesLabel: UILabel!
    @IBOutlet private weak var wallsLabel: UILabel!
    @IBOutlet private weak var bombsLabel: UILabel!
    @IBOutlet private weak var playViewContainer: UIView!

    private let filePreview: BeatmapFilePreview

    private var map: BeatmapSong?
    private var duration: TimeInterval?

    private var standardDifficulties: [BeatmapSongDifficulty]? {
        map?.standardDifficulties
    }

    private var selectedDifficulty: BeatmapSongDifficulty? {
        didSet {
            guard let difficulty = selectedDifficulty else { return }
            updateSongInformation(for: difficulty)
        }
    }

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
        let zipDataSource = ZIPBeatmapLoaderDataSource(with: filePreview.url)
        let loader = BeatmapLoader(dataSource: zipDataSource)

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

        // TODO: Load this in a background thread....
        guard let map = try? loader.loadMap(),
            !map.standardDifficulties.isEmpty,
            let easiestDifficulty = map.standardDifficulties.first
        else {
            // TODO: Show error message
            standardModeViewContainer.isHidden = true
            return
        }

        let manager = FileManager.default
        let destinationURL = manager.temporaryDirectory.appendingPathComponent("song.ogg")

        do {
            // TODO: Improve this: load from memory
            try map.song.write(to: destinationURL)
            audioPlayer.loadItem(with: destinationURL, autoPlay: true)
        } catch {
            // TODO: Show error message
            standardModeViewContainer.isHidden = true
            return
        }

        // FIXME: add/substract song offset
        self.duration = audioPlayer.duration()
        bpmLabel.text = "\(preview.beatsPerMinute)"
        durationLabel.text = duration?.formatted

        playViewContainer.layer.borderColor = UIColor.white.cgColor
        playViewContainer.layer.borderWidth = 4
        playViewContainer.layer.cornerRadius = 26

        self.map = map

        segmentedControl.setTitleTextAttributes([
            .font: UIFont(name: "Teko-Regular", size: 20.0)!,
            .foregroundColor: UIColor.white
        ], for: .normal)

        segmentedControl.setTitleTextAttributes([
            .font: UIFont(name: "Teko-Regular", size: 20.0)!,
            .foregroundColor: UIColor.black
        ], for: .selected)

        segmentedControl.selectedSegmentTintColor = .white

        segmentedControl.removeAllSegments()

        for i in 0 ..< map.standardDifficulties.count {
            let difficulty = map.standardDifficulties[i]
            segmentedControl.insertSegment(withTitle: difficulty.name, at: i, animated: false)
        }

        segmentedControl.selectedSegmentIndex = 0
        self.selectedDifficulty = easiestDifficulty
    }

    // MARK: - Helper

    private func updateSongInformation(for difficulty: BeatmapSongDifficulty) {
        guard let duration = duration else { return }
        let notesPerSecond = (duration > 0.0) ? (Double(difficulty.noteCount)/duration):0.0
        notesPerSecondLabel.text = String(format: "%.02f", notesPerSecond)
        notesLabel.text = "\(difficulty.noteCount)"
        wallsLabel.text = "\(difficulty.wallCount)"
        bombsLabel.text = "\(difficulty.bombCount)"
    }

    // MARK: - Actions

    @IBAction private func segmentedControlChanged(_ sender: Any) {
        let index = segmentedControl.selectedSegmentIndex
        selectedDifficulty = standardDifficulties?[index]
    }

    @IBAction private func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func playAction(_ sender: Any) {
        guard let presentingViewController = presentingViewController,
            let duration = duration,
            let selectedDifficulty = selectedDifficulty
        else {
            return
        }

        dismiss(animated: true, completion: {
            let sceneViewController = SceneViewController(
                duration: duration,
                bpm: self.filePreview.preview.beatsPerMinute,
                songDifficulty: selectedDifficulty
            )

            sceneViewController.modalPresentationStyle = .overFullScreen
            presentingViewController.present(sceneViewController, animated: true, completion: nil)
        })
    }
}
