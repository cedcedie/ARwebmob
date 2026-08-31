import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Renders a teacher-authored lesson's uploaded content: nothing when no
/// content has been uploaded, a processing message while the server-side
/// PPTX-to-slide-image conversion (Task 8) is still running, and a
/// swipeable slide gallery once slide images are ready — or immediately
/// for the legacy case of a single already-viewable image URL that never
/// needed conversion (`status == null`).
class ContentViewer extends StatefulWidget {
  const ContentViewer({super.key, required this.imageUrls, required this.status});

  final List<String>? imageUrls;
  final String? status;

  @override
  State<ContentViewer> createState() => _ContentViewerState();
}

class _ContentViewerState extends State<ContentViewer> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls == null || urls.isEmpty) return const SizedBox.shrink();

    if (widget.status == 'processing') {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Expanded(child: Text("Processing your teacher's uploaded content...")),
          ],
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              pageController: _controller,
              itemCount: urls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(urls[index]),
                // A slide image can fail to load (network hiccup, an
                // expired signed URL) — fall back to a plain icon instead
                // of letting the uncaught NetworkImageLoadException bubble
                // up through the image resource service.
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${_currentIndex + 1} / ${urls.length}'),
        ],
      ),
    );
  }
}
