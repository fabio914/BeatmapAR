import UIKit

protocol SongCellDelegate: AnyObject {
    func song(_ cell: SongCell, didSelectFile: BeatmapFilePreview)
    func song(_ cell: SongCell, didDeleteFile: BeatmapFilePreview)
}

final class SongCell: TableViewCellControllerWithView<SongCellView> {

    private weak var delegate: SongCellDelegate?
    private let songFile: BeatmapFilePreview

    init(file: BeatmapFilePreview, delegate: SongCellDelegate? = nil) {
        self.songFile = file
        self.delegate = delegate
    }

    override func tableView(_ tableView: TableView, cell: SongCellView, forIndexPath indexPath: IndexPath) {
        cell.songNameLabel.text = songFile.preview.songName
        cell.artistNameLabel.text = songFile.preview.songAuthorName
        cell.coverImageView.image = songFile.preview.coverImage
    }

    override func cellHeight() -> CGFloat {
        60
    }

    override func canSelect() -> Bool {
        true
    }

    override func selectionStyle() -> UITableViewCell.SelectionStyle {
        .gray
    }

    override func selectAction() {
        table?.deselectCell(forController: self)
        delegate?.song(self, didSelectFile: songFile)
    }

    override func canEdit() -> Bool {
        true
    }

    override func deleteAction() {
        delegate?.song(self, didDeleteFile: songFile)
    }
}

final class SongCellView: TableViewCell {
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
}
