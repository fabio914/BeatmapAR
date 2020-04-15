import UIKit

public protocol TableViewController {

    /* weak */ var table: TableView? { get set }
}

// Controllers

open class TableViewCellController: TableViewController {

    weak public var table: TableView?

    public init() {
    }

    open func cellNibName() -> String {
        .init(describing: type(of: self))
    }

    open func cellIdentifier() -> String {
        cellNibName()
    }

    open func bundle() -> Bundle {
        .init(for: type(of: self))
    }

    open func cellHeight() -> CGFloat {
        0
    }

    open func expectedCellWidth() -> CGFloat {
        table?.frame.size.width ?? 0
    }

    open func canEdit() -> Bool {
        false
    }

    open func deleteAction() {
    }

    open func canSelect() -> Bool {
        false
    }

    open func selectAction() { }

    open func selectionStyle() -> UITableViewCell.SelectionStyle {
        .none
    }

    open func canBeReloaded() -> Bool {
        false
    }

    open func willDisplayCell() { }

    open func didEndDisplayingCell() { }

    open func tableView(_ tableView: TableView, cell: TableViewCell, forIndexPath indexPath: IndexPath) { }
}

open class TableViewCellControllerWithView<T: TableViewCell>: TableViewCellController {

    override open func tableView(_ tableView: TableView, cell: TableViewCell, forIndexPath indexPath: IndexPath) {

        if let cell = cell as? T {
            self.tableView(tableView, cell: cell, forIndexPath: indexPath)
        }
    }

    open func tableView(_ tableView: TableView, cell: T, forIndexPath indexPath: IndexPath) { }
}

open class TableViewSectionController: TableViewController {

    weak public var table: TableView?
    fileprivate var rows: [TableViewCellController] = []

    public init() {
    }

    open func headerNibName() -> String {
        .init(describing: type(of: self))
    }

    open func headerView() -> TableViewHeader? {
        nil
    }

    open func headerHeight() -> CGFloat {
        0
    }

    open func bundle() -> Bundle {
        .init(for: type(of: self))
    }

    final public func instantiateView() -> TableViewHeader? {
        let headerView = UINib(nibName: headerNibName(), bundle: bundle()).instantiate(withOwner: nil, options: nil).first as? TableViewHeader
        headerView?.controller = self
        return headerView
    }
}

// Cells
open class TableViewCell: UITableViewCell {

    weak public var controller: TableViewCellController?
}

open class TableViewHeader: UIView {

    weak public var controller: TableViewSectionController?
}

final public class TableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    private var sections: [TableViewSectionController] = []

    // MARK: Initialization
    override public init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        configure()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }

    private func configure() {
        delegate = self
        dataSource = self
        separatorStyle = .none
        allowsSelectionDuringEditing = false
    }

    private func append(_ rows: [TableViewController]) -> (paths: [NSIndexPath], set: NSIndexSet) {

        let rowsToUse = rows.filter { $0 is TableViewCellController || $0 is TableViewSectionController }

        var indices: [NSIndexPath] = []
        let indexSet = NSMutableIndexSet()

        guard !rowsToUse.isEmpty else {
            return (indices, indexSet)
        }

        var currentSection: TableViewSectionController? = sections.last
        var currentSectionSize = currentSection?.rows.count ?? 0

        for item in rowsToUse {

            if let row = item as? TableViewCellController {

                if currentSection == nil {

                    let section = TableViewSectionController()
                    currentSection = section
                    currentSection?.table = self
                    currentSectionSize = 0
                    sections.append(section)
                    section.rows = []

                    indexSet.add(sections.count - 1)
                }

                currentSection?.rows.append(row)
                row.table = self
                currentSectionSize += 1
                indices.append(NSIndexPath(row: sections[sections.count - 1].rows.count - 1, section: sections.count - 1))
            } else if let section = item as? TableViewSectionController {

                if let current = currentSection, currentSectionSize == 0 {
                    current.rows.append(TableViewCellController())
                    indices.append(NSIndexPath(row: sections[sections.count - 1].rows.count - 1, section: sections.count - 1))
                }

                currentSection = section
                section.table = self
                currentSectionSize = 0
                sections.append(section)
                section.rows = []

                indexSet.add(sections.count - 1)

                if section === (rowsToUse.last as? TableViewSectionController) {
                    currentSection?.rows.append(TableViewCellController())
                    indices.append(NSIndexPath(row: sections[sections.count - 1].rows.count - 1, section: sections.count - 1))
                }
            }
        }

        return (indices, indexSet)
    }

    // MARK: - Public methods

    public func clearRows() {
        sections = []
        reloadData()
    }

    public func setRows(_ rows: [TableViewController]) {
        sections = []
        _ = append(rows)
        reloadData()
    }

    public func isEmpty() -> Bool {
        sections.isEmpty
    }

    public func reloadCell(forController controller: TableViewCellController, animation: UITableView.RowAnimation = .none) {

        if let index = indexPath(forController: controller) {
            self.reloadRows(at: [index as IndexPath], with: animation)
        }
    }

    public func deselectCell(forController controller: TableViewCellController, animated: Bool = false) {

        if let index = indexPath(forController: controller) {
            self.deselectRow(at: index as IndexPath, animated: animated)
        }
    }

    public func selectCell(
        forController controller: TableViewCellController,
        animated: Bool = false,
        scrollPosition: UITableView.ScrollPosition = .none
    ) {
        if let index = indexPath(forController: controller) {
            self.selectRow(at: index as IndexPath, animated: animated, scrollPosition: scrollPosition)
        }
    }

    public func deleteCell(forController controller: TableViewCellController, with animation: UITableView.RowAnimation = .none) {

        if let index = indexPath(forController: controller) {

            let section = sections[index.section]
            section.rows.remove(at: index.row)

            if section.rows.isEmpty {
                sections.remove(at: index.section)
                self.deleteSections(IndexSet(integer: index.section), with: animation)
                return
            }

            self.deleteRows(at: [index as IndexPath], with: animation)
        }
    }

    public func scrollController(_ controller: TableViewCellController, at scrollPosition: UITableView.ScrollPosition = .top, animated: Bool = true) {

        if let index = indexPath(forController: controller) {

            scrollToRow(at: index as IndexPath, at: scrollPosition, animated: animated)
        }
    }

    // MARK: - Logic

    private func controller(forIndexPath indexPath: IndexPath) -> TableViewCellController? {

        guard indexPath.section >= 0 &&
            indexPath.section < sections.count &&
            indexPath.row >= 0 &&
            indexPath.row < sections[indexPath.section].rows.count
        else {
            return nil
        }

        return sections[indexPath.section].rows[indexPath.row]
    }

    public func controller(forPoint point: CGPoint) -> TableViewCellController? {

        guard let indexPath = indexPathForRow(at: point) else {
            return nil
        }

        return controller(forIndexPath: indexPath)
    }

    private func sectionController(forSectionIndex index: Int) -> TableViewSectionController? {

        guard index >= 0 && index < sections.count else {
            return nil
        }

        return sections[index]
    }

    private func indexPath(forController controller: TableViewCellController) -> NSIndexPath? {

        for i in 0 ..< sections.count {
            let section = sections[i]

            for j in 0 ..< section.rows.count where section.rows[j] === controller {
                return NSIndexPath(row: j, section: i)
            }
        }

        return nil
    }

    private func cell(forController controller: TableViewCellController) -> TableViewCell {

        var cell = dequeueReusableCell(withIdentifier: controller.cellIdentifier())

        if cell == nil {
            register(UINib(nibName: controller.cellNibName(), bundle: controller.bundle()), forCellReuseIdentifier: controller.cellIdentifier())
            cell = self.dequeueReusableCell(withIdentifier: controller.cellIdentifier())
        }

        if let cell = cell as? TableViewCell {
            return cell
        } else {
            return TableViewCell()
        }
    }

    // MARK: - Delegate

    public func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionController(forSectionIndex: section)?.rows.count ?? 0
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sectionController(forSectionIndex: section)?.headerHeight() ?? 0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let controller = sectionController(forSectionIndex: section)
        let headerView = controller?.headerView()
        headerView?.controller = controller
        return headerView
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        controller(forIndexPath: indexPath)?.cellHeight() ?? 0
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        controller(forIndexPath: indexPath)?.cellHeight() ?? UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let controller = controller(forIndexPath: indexPath) else {
            return UITableViewCell()
        }

        let cell = self.cell(forController: controller)

        if cell.controller !== controller || controller.canBeReloaded() {

            cell.controller = controller

            if controller.canSelect() {

                cell.selectionStyle = controller.selectionStyle()
            }

            controller.tableView(self, cell: cell, forIndexPath: indexPath)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        controller(forIndexPath: indexPath)?.canSelect() ?? false
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        (controller(forIndexPath: indexPath)?.canSelect() ?? false) ? indexPath:nil
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        controller(forIndexPath: indexPath)?.selectAction()
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        controller(forIndexPath: indexPath)?.canEdit() ?? false
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            controller(forIndexPath: indexPath)?.deleteAction()
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        controller(forIndexPath: indexPath)?.willDisplayCell()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        controller(forIndexPath: indexPath)?.didEndDisplayingCell()
    }

    // MARK: - Deinit

    deinit {
        dataSource = nil
        delegate = nil
    }
}
