import UIKit

class SidebarPrimaryViewController: UIViewController {

    var onItemSelected: ((SidebarItemModel) -> Void)?

    private var items: [SidebarItemModel]
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, SidebarItemModel>!
    private var selectedItemId: String?

    // MARK: - Init

    init(title: String?, items: [SidebarItemModel]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupGlassBackground()
        setupCollectionView()
        applySnapshot(animated: false)
    }

    // MARK: - Glass Background

    private func setupGlassBackground() {
        let effectView: UIVisualEffectView
        if #available(iOS 26.0, *) {
            // Native liquid glass effect introduced in iOS 26
            let glass = UIGlassEffect()
            effectView = UIVisualEffectView(effect: glass)
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
        effectView.frame = view.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(effectView, at: 0)
    }

    // MARK: - Collection View Setup

    private func setupCollectionView() {
        // .sidebar appearance gives the native iPadOS sidebar look
        var listConfig = UICollectionLayoutListConfiguration(appearance: .sidebar)
        listConfig.showsSeparators = false
        listConfig.backgroundColor = .clear

        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        view.addSubview(collectionView)

        let cellReg = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItemModel> {
            [weak self] cell, _, item in
            self?.configure(cell: cell, for: item)
        }

        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { cv, indexPath, item in
            cv.dequeueConfiguredReusableCell(using: cellReg, for: indexPath, item: item)
        }
    }

    private func configure(cell: UICollectionViewListCell, for item: SidebarItemModel) {
        var content = cell.defaultContentConfiguration()
        content.text = item.title

        if let icon = item.resolvedIcon {
            content.image = icon
            content.imageProperties.tintColor = .label
            content.imageProperties.maximumSize = CGSize(width: 22, height: 22)
        }

        cell.contentConfiguration = content

        // Badge
        if let badge = item.badge, !badge.isEmpty {
            var accessories: [UICellAccessory] = []
            let label = UILabel()
            label.text = badge
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .secondaryLabel
            accessories.append(.customView(
                configuration: .init(customView: label, placement: .trailing())
            ))
            cell.accessories = accessories
        } else {
            cell.accessories = []
        }

        // Highlight selected item
        var bg = UIBackgroundConfiguration.listSidebarCell()
        if item.id == selectedItemId {
            bg.backgroundColor = .tintColor.withAlphaComponent(0.15)
            bg.cornerRadius = 10
        }
        cell.backgroundConfiguration = bg
    }

    // MARK: - Snapshot

    private func applySnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SidebarItemModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Public API

    func updateItems(_ newItems: [SidebarItemModel]) {
        items = newItems
        applySnapshot()
    }

    func selectItem(id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        selectedItemId = id
        let indexPath = IndexPath(item: idx, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
        applySnapshot()
        onItemSelected?(items[idx])
    }
}

// MARK: - UICollectionViewDelegate

extension SidebarPrimaryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        selectedItemId = item.id
        // Reload to update selection highlight
        applySnapshot()
        onItemSelected?(item)
    }
}
