import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_native_sidebar_platform_interface.dart';

/// An implementation of [IosNativeSidebarPlatform] that uses method channels.
class MethodChannelIosNativeSidebar extends IosNativeSidebarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_native_sidebar');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
