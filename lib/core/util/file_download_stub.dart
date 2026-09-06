/// Non-web implementation of [downloadTextFile]: there is no browser to hand
/// a file to, so this reports failure rather than pretending to save.
bool downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  return false;
}
