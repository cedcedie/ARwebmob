import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web implementation: build a Blob, point a hidden anchor at it, click it,
/// then release the object URL.
///
/// The content is encoded as UTF-8 bytes rather than handed over as a Dart
/// string so that non-ASCII characters (Filipino names, `·`, `–`) survive
/// intact — and any BOM the caller prepended stays the first byte, which is
/// what makes Excel open the file in the right encoding.
bool downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  final bytes = utf8.encode(content);
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
