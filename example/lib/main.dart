import 'package:flutter/material.dart';
import 'package:ios_native_sidebar/ios_native_sidebar.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Native Sidebar Demo', debugShowCheckedModeBanner: false, home: SidebarDemoPage());
  }
}

// ── Demo items ─────────────────────────────────────────────────────────────

final _items = [
  const NativeSidebarItem(id: 'home', title: 'Home', systemImage: 'house'),
  const NativeSidebarItem(id: 'explore', title: 'Explore', systemImage: 'safari'),
  const NativeSidebarItem(id: 'library', title: 'Library', systemImage: 'books.vertical', badge: '3'),
  const NativeSidebarItem(id: 'settings', title: 'Settings', systemImage: 'gear'),
];

// ── Demo page ──────────────────────────────────────────────────────────────

class SidebarDemoPage extends StatefulWidget {
  const SidebarDemoPage({super.key});

  @override
  State<SidebarDemoPage> createState() => _SidebarDemoPageState();
}

class _SidebarDemoPageState extends State<SidebarDemoPage> {
  NativeSidebarStyle _style = NativeSidebarStyle.sidebarAdaptable;
  String _selectedId = 'home';

  @override
  Widget build(BuildContext context) {
    return NativeSidebar(
      title: "Sidebar",
      largeTitleDisplayMode: true,
      style: NativeSidebarStyle.sidebarAdaptable,
      items: _items,
      selectedItemId: _selectedId,
      onItemSelected: (item) => setState(() => _selectedId = item.id),
      builder: (context, state) {
        return _DetailContent(
          selectedId: state.selectedItemId ?? _selectedId,
          isSidebarVisible: state.isSidebarVisible,
          currentStyle: _style,
          onToggleStyle:
              () => setState(() {
                _style = _style == NativeSidebarStyle.sidebarAdaptable ? NativeSidebarStyle.splitView : NativeSidebarStyle.sidebarAdaptable;
              }),
        );
      },
    );
  }
}

// ── Detail content ─────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  final String selectedId;
  final bool isSidebarVisible;
  final NativeSidebarStyle currentStyle;
  final VoidCallback onToggleStyle;

  const _DetailContent({required this.selectedId, required this.isSidebarVisible, required this.currentStyle, required this.onToggleStyle});

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).padding);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(selectedId)), backgroundColor: Colors.blueAccent),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(left: MediaQuery.of(context).padding.left),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(selectedId), size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(_titleFor(selectedId), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(_descFor(selectedId), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),
              _StatusBadge(isSidebarVisible: isSidebarVisible, style: currentStyle),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(String id) => switch (id) {
    'home' => 'Home',
    'explore' => 'Explore',
    'library' => 'Library',
    'settings' => 'Settings',
    _ => 'Content',
  };

  IconData _iconFor(String id) => switch (id) {
    'home' => Icons.home_outlined,
    'explore' => Icons.explore_outlined,
    'library' => Icons.menu_book_outlined,
    'settings' => Icons.settings_outlined,
    _ => Icons.circle_outlined,
  };

  String _descFor(String id) => switch (id) {
    'home' => 'Your personalised feed and recent activity.',
    'explore' => 'Discover new content from across the app.',
    'library' => 'Your saved items and reading list.',
    'settings' => 'Preferences, account, and app options.',
    _ => '',
  };
}

class _StatusBadge extends StatelessWidget {
  final bool isSidebarVisible;
  final NativeSidebarStyle style;

  const _StatusBadge({required this.isSidebarVisible, required this.style});

  @override
  Widget build(BuildContext context) {
    final styleName = style == NativeSidebarStyle.sidebarAdaptable ? 'sidebarAdaptable' : 'splitView';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
      child: Text(
        'Style: $styleName  •  Sidebar: ${isSidebarVisible ? 'visible' : 'hidden'}',
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }
}
