import UIKit

final class SongsViewController: UIViewController {

    @IBOutlet private weak var tableView: TableView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private var first = true

    init() {
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        tableView.indicatorStyle = .white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if first {
            reload()
            first = false
        }
    }

    @objc private func reload() {
        // TODO: Move this to a background thread
        let previews = BeatmapFilePreviewLoader()?
            .loadFilePreviews()
            .sorted(by: { $0.preview.songName < $1.preview.songName })

        let previewCells = (previews ?? []).map({ SongCell(file: $0, delegate: self) })

        tableView.setRows([TestSceneCell(delegate: self)] + previewCells)
        tableView.refreshControl?.endRefreshing()
    }
}

extension SongsViewController: TestSceneCellDelegate {

    func didSelectTestScene(_ cell: TestSceneCell) {
        let viewController = TestSceneViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true, completion: nil)
    }
}

extension SongsViewController: SongCellDelegate {

    func song(_ cell: SongCell, didSelectFile file: BeatmapFilePreview) {
        let viewController = SongViewController(filePreview: file)
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true, completion: nil)
    }

    func song(_ cell: SongCell, didDeleteFile file: BeatmapFilePreview) {
        let manager = FileManager.default
        try? manager.removeItem(at: file.url)
        reload()
    }
}
