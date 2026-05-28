import UIKit

enum SidebarStyle {
    case sidebarAdaptable
    case splitView
}

class SidebarContainerViewController: UISplitViewController {

    private let sidebarStyle: SidebarStyle
    private let primaryVC: SidebarPrimaryViewController
    private let contentViewController: UIViewController
    private let onEvent: ([String: Any]) -> Void

    // MARK: - Init

    init(
        style: SidebarStyle,
        title: String?,
        items: [SidebarItemModel],
        contentViewController: UIViewController,
        onEvent: @escaping ([String: Any]) -> Void
    ) {
        self.sidebarStyle = style
        self.contentViewController = contentViewController
        self.onEvent = onEvent
        self.primaryVC = SidebarPrimaryViewController(title: title, items: items)
        super.init(style: .doubleColumn)

        primaryVC.onItemSelected = { [weak self] item in
            self?.handleItemSelected(item)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitView()
    }

    // MARK: - Configuration

    private func configureSplitView() {
        delegate = self

        // Primary column: native sidebar
        setViewController(primaryVC, for: .primary)

        // Secondary column: existing Flutter view controller (becomes the content pane)
        setViewController(contentViewController, for: .secondary)

        switch sidebarStyle {
        case .sidebarAdaptable:
            // Sidebar is beside content on iPad; on iPhone it overlays as a sheet
            preferredDisplayMode = .oneBesideSecondary
            preferredSplitBehavior = .tile
            presentsWithGesture = true

        case .splitView:
            // Always show sidebar beside content on iPad
            preferredDisplayMode = .oneBesideSecondary
            preferredSplitBehavior = .tile
            presentsWithGesture = true
        }

        // Sidebar column width
        preferredPrimaryColumnWidthFraction = 0.28
        minimumPrimaryColumnWidth = 240
        maximumPrimaryColumnWidth = 320
    }

    // MARK: - Item Selection

    private func handleItemSelected(_ item: SidebarItemModel) {
        // On compact (iPhone), show the secondary column by revealing it
        show(.secondary)
        onEvent(["type": "itemSelected", "itemId": item.id])
    }

    // MARK: - Public Mutation API

    func updateItems(_ items: [SidebarItemModel]) {
        primaryVC.updateItems(items)
    }

    func selectItem(id: String) {
        primaryVC.selectItem(id: id)
    }

    func setSidebarVisible(_ visible: Bool) {
        if visible {
            preferredDisplayMode = .oneBesideSecondary
        } else {
            preferredDisplayMode = .secondaryOnly
        }
        let isVisible = preferredDisplayMode != .secondaryOnly
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": isVisible])
    }
}

// MARK: - UISplitViewControllerDelegate

extension SidebarContainerViewController: UISplitViewControllerDelegate {

    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        // Collapsed → compact (iPhone): user sees sidebar (primary) first
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": true])
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        // Expanded → regular (iPad): sidebar visibility depends on display mode
        let isVisible = displayMode != .secondaryOnly
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": isVisible])
    }

    func splitViewController(
        _ svc: UISplitViewController,
        collapseSecondary secondaryVC: UIViewController,
        onto primaryVC: UIViewController
    ) -> Bool {
        // Return true so that on iPhone (splitView) the sidebar (primary) is shown first
        // rather than jumping straight into the detail content
        return sidebarStyle == .splitView
    }
}
