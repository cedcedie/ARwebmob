import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/voice_over_controller.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';
import 'package:ar_science_explorer/features/student/ar_lab/scan_tab.dart';

class FakeFlutterTts implements FlutterTts {
  final List<String> spokenTexts = [];

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  void setCompletionHandler(VoidCallback callback) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ArLabViewModel _buildViewModel({required String lessonId, required bool hasAR}) {
  final firestore = FakeFirebaseFirestore();
  final quizAttemptService = QuizAttemptService(firestore: firestore);
  final accessCodeService = AccessCodeService(
    firestore: firestore,
    quizAttemptService: quizAttemptService,
  );

  return ArLabViewModel(
    lessonId: lessonId,
    title: 'Some lesson title',
    summary: 'Some lesson summary',
    hasAR: hasAR,
    markerIndex: hasAR ? 0 : null,
    isRead: false,
    hasPreTest: true,
    postTestEligible: true,
    postTestReason: null,
    studentId: '111111',
    accessCodeService: accessCodeService,
    onMarkAsRead: () async {},
    onStartPreTest: () {},
    onStartPostTest: () {},
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'shows "Point your camera" instruction when hasAR is true and nothing detected',
    (tester) async {
      final vm = _buildViewModel(lessonId: 'q1w1', hasAR: true);
      final voiceOverController = VoiceOverController(tts: FakeFlutterTts());

      await tester.pumpWidget(
        _wrap(ScanTab(vm: vm, voiceOverController: voiceOverController)),
      );
      await tester.pump();

      expect(find.textContaining('Point your camera'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the detected lesson\'s AR title and hides the "Point your camera" '
    'instruction once a marker is found',
    (tester) async {
      final vm = _buildViewModel(lessonId: 'q1w1', hasAR: true);
      final voiceOverController = VoiceOverController(tts: FakeFlutterTts());

      await tester.pumpWidget(
        _wrap(ScanTab(vm: vm, voiceOverController: voiceOverController)),
      );
      await tester.pump();

      vm.onMarkerFound('DemocritusAtomQ1W1');
      await tester.pump();

      expect(find.text('Democritus Atom'), findsOneWidget);
      expect(find.textContaining('Point your camera'), findsNothing);
    },
  );

  testWidgets(
    'shows a graceful fallback message and never builds EmbedUnity when hasAR is false',
    (tester) async {
      final vm = _buildViewModel(lessonId: 'q1w5', hasAR: false);
      final voiceOverController = VoiceOverController(tts: FakeFlutterTts());

      await tester.pumpWidget(
        _wrap(ScanTab(vm: vm, voiceOverController: voiceOverController)),
      );
      await tester.pump();

      expect(find.textContaining("doesn't have an AR model"), findsOneWidget);
      expect(find.byType(EmbedUnity), findsNothing);
    },
  );

  testWidgets(
    'ignores a malformed Unity message (invalid JSON) without throwing or '
    'changing UI state',
    (tester) async {
      final vm = _buildViewModel(lessonId: 'q1w1', hasAR: true);
      final voiceOverController = VoiceOverController(tts: FakeFlutterTts());

      await tester.pumpWidget(
        _wrap(ScanTab(vm: vm, voiceOverController: voiceOverController)),
      );
      await tester.pump();

      final embedUnity = tester.widget<EmbedUnity>(find.byType(EmbedUnity));

      expect(() => embedUnity.onMessageFromUnity?.call('not valid json{'), returnsNormally);
      await tester.pump();

      expect(vm.detectedLesson, isNull);
      expect(find.textContaining('Point your camera'), findsOneWidget);
    },
  );

  testWidgets(
    'ignores a well-formed JSON message missing the expected fields without '
    'throwing or changing UI state',
    (tester) async {
      final vm = _buildViewModel(lessonId: 'q1w1', hasAR: true);
      final voiceOverController = VoiceOverController(tts: FakeFlutterTts());

      await tester.pumpWidget(
        _wrap(ScanTab(vm: vm, voiceOverController: voiceOverController)),
      );
      await tester.pump();

      final embedUnity = tester.widget<EmbedUnity>(find.byType(EmbedUnity));

      expect(() => embedUnity.onMessageFromUnity?.call('{"unexpected":"shape"}'), returnsNormally);
      expect(() => embedUnity.onMessageFromUnity?.call('["not", "a", "map"]'), returnsNormally);
      await tester.pump();

      expect(vm.detectedLesson, isNull);
      expect(find.textContaining('Point your camera'), findsOneWidget);
    },
  );
}
