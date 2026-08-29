import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/voice_over_controller.dart';
import 'ar_lab_providers.dart';
import 'read_tab.dart';
import 'review_tab.dart';
import 'scan_tab.dart';

class ArLabScreen extends ConsumerStatefulWidget {
  const ArLabScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<ArLabScreen> createState() => _ArLabScreenState();
}

class _ArLabScreenState extends ConsumerState<ArLabScreen> {
  late final VoiceOverController _voiceOverController;

  @override
  void initState() {
    super.initState();
    _voiceOverController = VoiceOverController(tts: FlutterTts());
  }

  @override
  Widget build(BuildContext context) {
    final asyncViewModel = ref.watch(arLabViewModelProvider(widget.lessonId));

    return asyncViewModel.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Could not load this lesson: $error'))),
      data: (vm) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(vm.title),
            bottom: const TabBar(
              tabs: [Tab(text: 'Scan'), Tab(text: 'Read'), Tab(text: 'Review')],
            ),
          ),
          body: TabBarView(
            children: [
              ScanTab(vm: vm, voiceOverController: _voiceOverController),
              ReadTab(vm: vm),
              ReviewTab(vm: vm),
            ],
          ),
        ),
      ),
    );
  }
}
