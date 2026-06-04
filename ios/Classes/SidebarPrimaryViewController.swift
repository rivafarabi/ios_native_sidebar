import UIKit

class SidebarPrimaryViewController: UICollectionViewController {

    var onItemSelected: ((SidebarItemModel) -> Void)?

    private var items: [SidebarItemModel]
    private var dataSource: UICollectionViewDiffableDataSource<Int, SidebarItemModel>!
    private var selectedItemId: String?

    // MARK: - Init

    init(title: String?, largeTitleDisplayMode: Bool, items: [SidebarItemModel]) {
        self.items = items

        var listConfig = UICollectionLayoutListConfiguration(appearance: .sidebar)
        listConfig.showsSeparators = false
        listConfig.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

        super.init(collectionViewLayout: layout)
        self.title = title
        // .automatic: large title at rest, collapses to inline on scroll.
        // .never: inline title always.
        // The split view's internal column nav controller honours this without
        // needing an explicit UINavigationController wrapper.
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode ? .automatic : .never
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Using UICollectionViewController means collectionView.view IS the scroll view,
        // so the navigation bar can observe content offset for large-title collapsing.
        collectionView.backgroundColor = .clear
        setupGlassBackground()
        setupDataSource()
        applySnapshot(animated: false)
    }

    // MARK: - Glass Background

    private func setupGlassBackground() {
        // Set as backgroundView so it sits behind all cells and participates
        // in the scroll view's own layout (no frame management needed).
        let effectView: UIVisualEffectView
        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect()
            effectView = UIVisualEffectView(effect: glass)
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
        collectionView.backgroundView = effectView
    }

    // MARK: - Data Source

    private func setupDataSource() {
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

        if let name = item.systemImage, let icon = UIImage(systemName: name) {
            // SF Symbol — standard sidebar icon sizing
            content.image = icon
            content.imageProperties.tintColor = .label
            content.imageProperties.maximumSize = CGSize(width: 22, height: 22)
        } else if let data = item.imageData, let original = UIImage(data: data) {
            // Custom image — circular avatar, same container size as SF Symbol icons.
            // reservedLayoutSize ensures the image column reserves the same fixed
            // width as SF Symbol rows so text labels align across all cells.
            let avatarSize: CGFloat = 30
            content.image = makeCircularAvatar(from: original, size: avatarSize)
            content.imageProperties.maximumSize = CGSize(width: avatarSize, height: avatarSize)
            content.imageProperties.reservedLayoutSize = CGSize(
                width: UIListContentConfiguration.ImageProperties.standardDimension,
                height: UIListContentConfiguration.ImageProperties.standardDimension
            )
        }

        cell.contentConfiguration = content

        if let badge = item.badge, !badge.isEmpty {
            let label = UILabel()
            label.text = badge
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .secondaryLabel
            cell.accessories = [.customView(
                configuration: .init(customView: label, placement: .trailing())
            )]
        } else {
            cell.accessories = []
        }

        var bg = UIBackgroundConfiguration.listSidebarCell()
        if item.id == selectedItemId {
            bg.backgroundColor = .tintColor.withAlphaComponent(0.15)
            bg.cornerRadius = 10
        }
        cell.backgroundConfiguration = bg
    }

    // MARK: - Avatar Rendering

    /// Renders `image` into a circle of `size` × `size` points using
    /// aspect-fit (contain) mode: the image shrinks to fit inside the circle
    /// without cropping, and any remaining area is filled with a neutral
    /// background so the circle boundary is always complete.
    private func makeCircularAvatar(from image: UIImage, size: CGFloat) -> UIImage {
        let canvas = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { ctx in
            let circle = CGRect(origin: .zero, size: canvas)

            // Clip everything to the circle boundary
            ctx.cgContext.addEllipse(in: circle)
            ctx.cgContext.clip()

            // Neutral background visible where contain-fit leaves gaps
            UIColor.systemGray5.setFill()
            ctx.cgContext.fill(circle)

            // Cover (aspect-fill): scale so the shortest dimension fills the
            // circle; the excess on the longer axis is centred and clipped.
            let aspect = image.size.width / image.size.height
            let drawRect: CGRect
            if aspect >= 1.0 {
                // Wider than tall — fill by height, clip width overflow
                let w = size * aspect
                drawRect = CGRect(x: (size - w) / 2, y: 0, width: w, height: size)
            } else {
                // Taller than wide — fill by width, clip height overflow
                let h = size / aspect
                drawRect = CGRect(x: 0, y: (size - h) / 2, width: size, height: h)
            }
            image.draw(in: drawRect)
        }
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

extension SidebarPrimaryViewController {

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let item = items[indexPath.item]
        selectedItemId = item.id
        applySnapshot()
        onItemSelected?(item)
    }
}
