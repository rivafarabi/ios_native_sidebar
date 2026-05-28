import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_native_sidebar/ios_native_sidebar_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIosNativeSidebar platform = MethodChannelIosNativeSidebar();
  const MethodChannel channel = MethodChannel('ios_native_sidebar');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
