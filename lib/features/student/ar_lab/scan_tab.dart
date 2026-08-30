import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

import '../../../core/ar/voice_scripts_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/services/voice_over_controller.dart';
import 'ar_lab_providers.dart';

/// The AR Lab's Scan phase (PROJECT_FLOW.md Part 6.3): shows the live Unity
/// camera feed and overlays the description of whatever marker it currently
/// recognizes, plus optional voice narration controls.
class ScanTab extends StatefulWidget {
  const ScanTab({super.key, required this.vm, required this.voiceOverController});

  final ArLabViewModel vm;
  final VoiceOverController voiceOverController;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() => setState(() {});

  void _handleUnityMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return;
      final event = decoded['event'] as String?;
      final trackableName = decoded['trackableName'] as String?;
      if (trackableName == null) return;
      if (event == 'markerFound') {
        widget.vm.onMarkerFound(trackableName);
      } else if (event == 'markerLost') {
        widget.vm.onMarkerLost(trackableName);
      }
    } catch (error) {
      // A malformed or unrecognized message from Unity (bad JSON, wrong
      // shape, or a future event type) should never crash the Scan tab —
      // swallow it after logging for debugging.
      debugPrint('ScanTab: ignoring malformed Unity message: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.vm.hasAR) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "This lesson doesn't have an AR model — continue to the Read tab.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final scripts = kVoiceScripts[widget.vm.lessonId];

    return Stack(
      children: [
        Positioned.fill(
          child: EmbedUnity(onMessageFromUnity: _handleUnityMessage),
        ),
        if (widget.vm.detectedLesson == null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _InstructionOverlay(
              text: 'Point your camera at the printed marker for this lesson.',
            ),
          )
        else
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _DetectedLessonOverlay(lesson: widget.vm.detectedLesson!),
          ),
        if (scripts != null)
          Positioned(
            top: 16,
            right: 16,
            child: _VoiceControls(
              scripts: scripts,
              language: _language,
              onLanguageChanged: (value) => setState(() => _language = value),
              onPlay: () => widget.voiceOverController.playAll(
                scripts[_language] ?? const [],
                _language,
              ),
            ),
          ),
      ],
    );
  }
}

class _InstructionOverlay extends StatelessWidget {
  const _InstructionOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _DetectedLessonOverlay extends StatelessWidget {
  const _DetectedLessonOverlay({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final payload = lesson.arPayload;
    final keyIdeas = payload?.keyIdeas;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payload?.title ?? lesson.title,
              style: textTheme.titleLarge,
            ),
            if (payload?.subtitle != null)
              Text(payload!.subtitle!, style: textTheme.titleMedium),
            if (payload?.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(payload!.description!, style: textTheme.bodyLarge),
              ),
            if (keyIdeas != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final idea in keyIdeas) Text('• $idea', style: textTheme.bodyLarge),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceControls extends StatelessWidget {
  const _VoiceControls({
    required this.scripts,
    required this.language,
    required this.onLanguageChanged,
    required this.onPlay,
  });

  final Map<String, List<String>> scripts;
  final String language;
  final void Function(String) onLanguageChanged;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
              ],
              onChanged: (value) {
                if (value != null) onLanguageChanged(value);
              },
            ),
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: onPlay,
            ),
          ],
        ),
      ),
    );
  }
}
