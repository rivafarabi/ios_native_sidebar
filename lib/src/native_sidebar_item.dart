import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// A single entry shown in the native sidebar list.
class NativeSidebarItem {
  /// Unique identifier used to reference this item in callbacks and state.
  final String id;

  /// Display label rendered beside the icon.
  final String title;

  /// SF Symbol name (e.g. `'house'`, `'gear'`).
  /// Takes priority over [image] when both are provided.
  final String? sfIcon;

  /// Any Flutter [ImageProvider] (asset, network, file, memory).
  /// Encoded to PNG bytes and sent to native. [sfIcon] takes priority.
  final ImageProvider? image;

  /// Optional badge text shown on the trailing edge (e.g. `'3'` or `'New'`).
  final String? badge;

  const NativeSidebarItem({required this.id, required this.title, this.sfIcon, this.image, this.badge});

  /// Serialises this item for the method channel.
  /// [image] is resolved to PNG bytes before sending.
  Future<Map<String, dynamic>> toMap() async {
    final map = <String, dynamic>{'id': id, 'title': title};
    if (sfIcon != null) map['systemImage'] = sfIcon;
    if (badge != null) map['badge'] = badge;

    // Only encode image bytes when no SF Symbol is provided
    if (sfIcon == null && image != null) {
      final bytes = await _resolveImageBytes(image!);
      if (bytes != null) {
        map['imageData'] = bytes;
      }
    }

    return map;
  }

  static Future<Uint8List?> _resolveImageBytes(ImageProvider provider) async {
    try {
      final completer = Completer<ui.Image>();
      final stream = provider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (e, stack) {
          if (!completer.isCompleted) completer.completeError(e, stack);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final uiImage = await completer.future;
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
