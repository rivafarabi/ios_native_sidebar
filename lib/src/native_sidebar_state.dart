/// Describes the current state of the native sidebar passed to the builder.
class NativeSidebarState {
  /// Whether the sidebar panel is currently visible / expanded.
  ///
  /// On iPad this is `true` while the sidebar column is on screen.
  /// On iPhone (`splitView`) this is `true` while the user is on the
  /// sidebar list screen, and `false` once they navigate into the detail.
  final bool isSidebarVisible;

  /// The `id` of the currently selected [NativeSidebarItem], or `null`
  /// if nothing has been selected yet.
  final String? selectedItemId;

  const NativeSidebarState({
    required this.isSidebarVisible,
    this.selectedItemId,
  });

  NativeSidebarState copyWith({bool? isSidebarVisible, String? selectedItemId}) {
    return NativeSidebarState(
      isSidebarVisible: isSidebarVisible ?? this.isSidebarVisible,
      selectedItemId: selectedItemId ?? this.selectedItemId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NativeSidebarState &&
      other.isSidebarVisible == isSidebarVisible &&
      other.selectedItemId == selectedItemId;

  @override
  int get hashCode => Object.hash(isSidebarVisible, selectedItemId);
}
