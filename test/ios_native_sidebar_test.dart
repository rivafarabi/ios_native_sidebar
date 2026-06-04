import 'package:flutter_test/flutter_test.dart';
import 'package:ios_native_sidebar/ios_native_sidebar.dart';
import 'package:ios_native_sidebar/ios_native_sidebar_platform_interface.dart';
import 'package:ios_native_sidebar/ios_native_sidebar_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosNativeSidebarPlatform with MockPlatformInterfaceMixin implements IosNativeSidebarPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IosNativeSidebarPlatform initialPlatform = IosNativeSidebarPlatform.instance;

  test('$MethodChannelIosNativeSidebar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosNativeSidebar>());
  });

  test('NativeSidebarItem serialises correctly', () async {
    const item = NativeSidebarItem(id: 'home', title: 'Home', sfIcon: 'house', badge: '5');
    final map = await item.toMap();
    expect(map['id'], 'home');
    expect(map['title'], 'Home');
    expect(map['systemImage'], 'house');
    expect(map['badge'], '5');
  });

  test('NativeSidebarState equality', () {
    const a = NativeSidebarState(isSidebarVisible: true, selectedItemId: 'x');
    const b = NativeSidebarState(isSidebarVisible: true, selectedItemId: 'x');
    const c = NativeSidebarState(isSidebarVisible: false, selectedItemId: 'x');
    expect(a, equals(b));
    expect(a, isNot(equals(c)));
  });

  test('NativeSidebarState copyWith', () {
    const state = NativeSidebarState(isSidebarVisible: true);
    final updated = state.copyWith(selectedItemId: 'settings');
    expect(updated.isSidebarVisible, true);
    expect(updated.selectedItemId, 'settings');
  });
}
