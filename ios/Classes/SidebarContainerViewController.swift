import UIKit

// MARK: - SidebarStyle

enum SidebarStyle {
    case sidebarAdaptable
    case splitView
}

// MARK: - SidebarContainerViewController

class SidebarContainerViewController: UISplitViewController {

    private let sidebarStyle: SidebarStyle
    private let primaryVC: SidebarPrimaryViewController
    private let contentViewController: UIViewController
    private let onEvent: ([String: Any]) -> Void

    // Prevents stacking multiple pending fixContentSafeArea dispatches.
    private var pendingSafeAreaFix = false

    // MARK: - Init

    init(
        style: SidebarStyle,
        title: String?,
        largeTitleDisplayMode: Bool,
        items: [SidebarItemModel],
        contentViewController: UIViewController,
        onEvent: @escaping ([String: Any]) -> Void
    ) {
        self.sidebarStyle = style
        self.contentViewController = contentViewController
        self.onEvent = onEvent

        let primary = SidebarPrimaryViewController(
            title: title,
            largeTitleDisplayMode: largeTitleDisplayMode,
            items: items
        )
        self.primaryVC = primary

        super.init(style: .doubleColumn)

        primary.onItemSelected = { [weak self] item in
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewDidAppear fires after the first complete layout pass with the
        // view fully embedded in the window. Safe area values are current here.
        fixContentSafeArea()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Defer to the next run-loop turn so the content VC's view has had a
        // chance to propagate the post-layout safe-area values. Reading
        // contentViewController.view.safeAreaInsets synchronously here returns
        // a stale value because UIKit updates child views asynchronously.
        guard !pendingSafeAreaFix else { return }
        pendingSafeAreaFix = true
        DispatchQueue.main.async { [weak self] in
            self?.pendingSafeAreaFix = false
            self?.fixContentSafeArea()
        }
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        // Run after the transition animation so safe areas reflect the new
        // window size (handles Stage Manager windowed ↔ fullscreen changes).
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.fixContentSafeArea()
        }
    }

    // MARK: - Safe Area Correction

    /// Cancels the extra top safe-area that UISplitViewController adds to the
    /// secondary column to align it with the primary column's navigation bar.
    ///
    /// Flutter manages its own AppBar / status-bar padding, so any inset beyond
    /// the window's true top safe area (status bar / notch) inflates
    /// MediaQuery.padding.top. We cancel the excess by applying an equal
    /// negative additionalSafeAreaInsets.top to the content view controller.
    private func fixContentSafeArea() {
        guard let window = view.window else { return }
        let windowTop = window.safeAreaInsets.top
        let contentTop = contentViewController.view.safeAreaInsets.top
        guard contentTop > windowTop else { return }
        contentViewController.additionalSafeAreaInsets.top -= (contentTop - windowTop)
    }

    // MARK: - Configuration

    private func configureSplitView() {
        delegate = self

        setViewController(primaryVC, for: .primary)
        setViewController(contentViewController, for: .secondary)

        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = true

        preferredPrimaryColumnWidthFraction = 0.28
        minimumPrimaryColumnWidth = 240
        maximumPrimaryColumnWidth = 320
    }

    // MARK: - Item Selection

    private func handleItemSelected(_ item: SidebarItemModel) {
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
        preferredDisplayMode = visible ? .oneBesideSecondary : .secondaryOnly
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": visible])
    }
}

// MARK: - UISplitViewControllerDelegate

extension SidebarContainerViewController: UISplitViewControllerDelegate {

    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": true])
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        let isVisible = displayMode != .secondaryOnly
        onEvent(["type": "sidebarVisibilityChanged", "isVisible": isVisible])
    }

    func splitViewController(
        _ svc: UISplitViewController,
        collapseSecondary secondaryVC: UIViewController,
        onto primaryVC: UIViewController
    ) -> Bool {
        return sidebarStyle == .splitView
    }
}
