import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_sidebar_item.dart';
import 'native_sidebar_state.dart';
import 'native_sidebar_style.dart';

typedef NativeSidebarBuilder = Widget Function(
  BuildContext context,
  NativeSidebarState state,
);

/// A widget that renders a native iPadOS/iOS sidebar using
/// [UISplitViewController] with iOS 26 liquid glass aesthetics.
///
/// On iOS the widget initialises a native split-view as the app's root view
/// controller. The [builder] output fills the secondary (detail) column
/// because the underlying [FlutterViewController] becomes that column.
///
/// On non-iOS platforms a pure-Flutter fallback is rendered:
/// [NavigationRail] on wide screens, [Drawer] on narrow screens.
class NativeSidebar extends StatefulWidget {
  /// Visual style: collapsible sidebar or always-visible split view.
  final NativeSidebarStyle style;

  /// Optional title displayed in the sidebar's navigation bar.
  final String? title;

  /// Items to display in the sidebar list.
  final List<NativeSidebarItem> items;

  /// The currently selected item id. When changed, the native sidebar
  /// updates its selection highlight automatically.
  final String? selectedItemId;

  /// Called when the user taps a sidebar row on the native side.
  final ValueChanged<NativeSidebarItem>? onItemSelected;

  /// Builder that receives the current [NativeSidebarState] and returns the
  /// detail content. On iOS this output fills the split-view secondary column.
  final NativeSidebarBuilder builder;

  const NativeSidebar({
    super.key,
    required this.style,
    required this.items,
    required this.builder,
    this.title,
    this.selectedItemId,
    this.onItemSelected,
  });

  @override
  State<NativeSidebar> createState() => _NativeSidebarState();
}

class _NativeSidebarState extends State<NativeSidebar> {
  static const _channel = MethodChannel('ios_native_sidebar');
  static const _events = EventChannel('ios_native_sidebar/events');

  StreamSubscription<dynamic>? _eventSub;
  NativeSidebarState _state = const NativeSidebarState(isSidebarVisible: true);
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _subscribeToEvents();
      _initialize();
    }
  }

  @override
  void didUpdateWidget(NativeSidebar old) {
    super.didUpdateWidget(old);
    if (!Platform.isIOS || !_initialized) return;

    if (_itemsChanged(old.items, widget.items)) {
      _updateItems();
    }
    if (widget.selectedItemId != old.selectedItemId &&
        widget.selectedItemId != null) {
      _channel.invokeMethod('selectItem', {'itemId': widget.selectedItemId});
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    if (Platform.isIOS && _initialized) {
      _channel.invokeMethod('teardown');
    }
    super.dispose();
  }

  // ── Native bridge ─────────────────────────────────────────────────────────

  void _subscribeToEvents() {
    _eventSub = _events.receiveBroadcastStream().listen(_handleEvent);
  }

  void _handleEvent(dynamic raw) {
    if (raw is! Map) { return; }
    final event = Map<String, dynamic>.from(raw);
    final type = event['type'] as String?;
    switch (type) {
      case 'initialized':
        setState(() => _initialized = true);
      case 'itemSelected':
        final id = event['itemId'] as String?;
        if (id == null) break;
        final item = widget.items.firstWhere(
          (i) => i.id == id,
          orElse: () => NativeSidebarItem(id: id, title: id),
        );
        setState(() => _state = _state.copyWith(selectedItemId: id));
        widget.onItemSelected?.call(item);
      case 'sidebarVisibilityChanged':
        final visible = event['isVisible'] as bool? ?? true;
        setState(() => _state = _state.copyWith(isSidebarVisible: visible));
    }
  }

  Future<void> _initialize() async {
    final itemMaps = await Future.wait(widget.items.map((i) => i.toMap()));
    await _channel.invokeMethod('initialize', {
      'style': widget.style.name,
      'items': itemMaps,
      if (widget.title != null) 'title': widget.title,
    });
    if (widget.selectedItemId != null) {
      await _channel.invokeMethod(
          'selectItem', {'itemId': widget.selectedItemId});
    }
  }

  Future<void> _updateItems() async {
    final itemMaps = await Future.wait(widget.items.map((i) => i.toMap()));
    await _channel.invokeMethod('updateItems', {'items': itemMaps});
  }

  bool _itemsChanged(
      List<NativeSidebarItem> a, List<NativeSidebarItem> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].title != b[i].title ||
          a[i].systemImage != b[i].systemImage ||
          a[i].badge != b[i].badge) return true;
    }
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // On iOS the native UISplitViewController is the root shell;
      // the builder output fills the secondary (detail) column.
      return widget.builder(context, _state);
    }
    // ── Flutter fallback for non-iOS ──────────────────────────────────────
    return _FlutterSidebarFallback(
      style: widget.style,
      items: widget.items,
      selectedItemId: widget.selectedItemId ?? _state.selectedItemId,
      onItemSelected: (item) {
        setState(() => _state = _state.copyWith(selectedItemId: item.id));
        widget.onItemSelected?.call(item);
      },
      builder: widget.builder,
      state: _state,
    );
  }
}

// ── Pure-Flutter fallback ──────────────────────────────────────────────────

class _FlutterSidebarFallback extends StatefulWidget {
  final NativeSidebarStyle style;
  final List<NativeSidebarItem> items;
  final String? selectedItemId;
  final ValueChanged<NativeSidebarItem> onItemSelected;
  final NativeSidebarBuilder builder;
  final NativeSidebarState state;

  const _FlutterSidebarFallback({
    required this.style,
    required this.items,
    required this.selectedItemId,
    required this.onItemSelected,
    required this.builder,
    required this.state,
  });

  @override
  State<_FlutterSidebarFallback> createState() =>
      _FlutterSidebarFallbackState();
}

class _FlutterSidebarFallbackState extends State<_FlutterSidebarFallback> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    if (isWide) {
      return _buildRailLayout(context);
    }
    return _buildDrawerLayout(context);
  }

  Widget _buildRailLayout(BuildContext context) {
    final selectedIndex = widget.items
        .indexWhere((i) => i.id == widget.selectedItemId);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            extended: true,
            onDestinationSelected: (idx) =>
                widget.onItemSelected(widget.items[idx]),
            destinations: widget.items.map((item) {
              return NavigationRailDestination(
                icon: item.systemImage != null
                    ? Icon(IconData(
                        _sfSymbolToMaterialCode(item.systemImage!),
                        fontFamily: 'MaterialIcons',
                      ))
                    : const Icon(Icons.circle_outlined),
                label: Text(item.title),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.builder(context, widget.state)),
        ],
      ),
    );
  }

  Widget _buildDrawerLayout(BuildContext context) {
    if (widget.style == NativeSidebarStyle.splitView) {
      // On narrow screens, splitView becomes a NavigationStack equivalent:
      // show a list first, push detail on selection.
      return Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => _SidebarListPage(
              items: widget.items,
              onItemSelected: widget.onItemSelected,
              builder: widget.builder,
              state: widget.state,
            ),
          );
        },
      );
    }

    // sidebarAdaptable: content + hamburger that opens a Drawer
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: widget.items.map((item) {
            return ListTile(
              leading: item.systemImage != null
                  ? const Icon(Icons.circle)
                  : null,
              title: Text(item.title),
              selected: item.id == widget.selectedItemId,
              onTap: () {
                Navigator.of(context).pop();
                widget.onItemSelected(item);
              },
            );
          }).toList(),
        ),
      ),
      body: widget.builder(context, widget.state),
    );
  }

  // Very rough SF Symbol → Material icon fallback (common symbols only)
  int _sfSymbolToMaterialCode(String name) {
    const map = {
      'house': 0xe3af,
      'gear': 0xe8b8,
      'safari': 0xe80b,
      'books.vertical': 0xe865,
      'person': 0xe7fd,
      'star': 0xe838,
      'heart': 0xe87d,
      'magnifyingglass': 0xe8b6,
      'bell': 0xe7f4,
      'bookmark': 0xe866,
    };
    return map[name] ?? 0xe3af;
  }
}

class _SidebarListPage extends StatefulWidget {
  final List<NativeSidebarItem> items;
  final ValueChanged<NativeSidebarItem> onItemSelected;
  final NativeSidebarBuilder builder;
  final NativeSidebarState state;

  const _SidebarListPage({
    required this.items,
    required this.onItemSelected,
    required this.builder,
    required this.state,
  });

  @override
  State<_SidebarListPage> createState() => _SidebarListPageState();
}

class _SidebarListPageState extends State<_SidebarListPage> {
  NativeSidebarState _state = const NativeSidebarState(isSidebarVisible: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: widget.items.map((item) {
          return ListTile(
            title: Text(item.title),
            selected: item.id == _state.selectedItemId,
            onTap: () {
              widget.onItemSelected(item);
              setState(() {
                _state = NativeSidebarState(
                  isSidebarVisible: false,
                  selectedItemId: item.id,
                );
              });
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => Scaffold(
                    appBar: AppBar(),
                    body: widget.builder(ctx, _state),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
