import UIKit

protocol TestSceneCellDelegate: AnyObject {
    func didSelectTestScene(_ cell: TestSceneCell)
}

final class TestSceneCell: TableViewCellControllerWithView<SongCellView> {

    private weak var delegate: TestSceneCellDelegate?

    init(delegate: TestSceneCellDelegate? = nil) {
        self.delegate = delegate
    }

    override func cellNibName() -> String {
        "SongCell"
    }

    override func tableView(_ tableView: TableView, cell: SongCellView, forIndexPath indexPath: IndexPath) {
        cell.songNameLabel.text = "Test Scene"
        cell.artistNameLabel.text = "Fabio"
        cell.coverImageView.image = #imageLiteral(resourceName: "Icon")
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
        delegate?.didSelectTestScene(self)
    }
}
