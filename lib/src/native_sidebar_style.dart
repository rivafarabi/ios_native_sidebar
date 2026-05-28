enum NativeSidebarStyle {
  /// Sidebar that can be collapsed; slides over content on iPhone.
  sidebarAdaptable,

  /// Always-visible sidebar on iPad; becomes a navigation root on iPhone
  /// where selecting an item pushes into the detail content.
  splitView,
}
