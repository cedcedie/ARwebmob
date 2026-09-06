/// Hands the user a generated text file to save.
///
/// The teacher portal is the only place this is used, and it only ever runs
/// on the web — but `lib/` is compiled for Android too, so the browser APIs
/// live behind a conditional import rather than being referenced directly.
/// On any non-web target this is a no-op that reports failure, so a caller
/// can tell the user rather than appearing to succeed.
library;

import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart'
    as impl;

/// Triggers a browser download of [content] named [fileName].
///
/// Returns false when the platform has no way to save a file (i.e. anywhere
/// but web), so callers can show a message instead of silently doing nothing.
bool downloadTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  return impl.downloadTextFile(
    fileName: fileName,
    content: content,
    mimeType: mimeType,
  );
}
