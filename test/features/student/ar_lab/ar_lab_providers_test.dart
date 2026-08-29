import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';

StudentRecord _sampleStudent() => StudentRecord.fromJson(const {
      'id': '111111',
      'studentId': '111111',
      'name': 'Juan Dela Cruz',
      'grade': '7',
      'section': 'Rizal',
      'scores': {'chemistry': null, 'biology': null, 'physics': null},
      'completedLessonIds': <String>[],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': <String>[],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
      'isArchived': false,
    });

Future<ArLabViewModel> _buildViewModel(String lessonId) async {
  final firestore = FakeFirebaseFirestore();
  final studentRepository = StudentRepository(firestore: firestore);
  final lessonRepository = LessonRepository(firestore: firestore);
  final quizAttemptService = QuizAttemptService(firestore: firestore);
  final accessCodeService = AccessCodeService(
    firestore: firestore,
    quizAttemptService: quizAttemptService,
  );
  await studentRepository.saveStudent(_sampleStudent());

  return buildArLabViewModel(
    studentId: '111111',
    lessonId: lessonId,
    lessonRepository: lessonRepository,
    studentRepository: studentRepository,
    quizAttemptService: quizAttemptService,
    accessCodeService: accessCodeService,
    preTestLessonIds: const {},
    onStartPreTest: () {},
    onStartPostTest: () {},
  ).first;
}

void main() {
  test('q1w1 has AR content with its own marker index and title', () async {
    final viewModel = await _buildViewModel('q1w1');

    expect(viewModel.hasAR, true);
    expect(viewModel.markerIndex, 0);
    expect(viewModel.title, 'Scientific Models and the Particle Model of Matter');
  });

  test('q1w5 has no AR content', () async {
    final viewModel = await _buildViewModel('q1w5');

    expect(viewModel.hasAR, false);
    expect(viewModel.markerIndex, isNull);
  });

  test('onMarkerFound/onMarkerLost track the currently detected lesson', () async {
    final viewModel = await _buildViewModel('q1w1');

    expect(viewModel.detectedLesson, isNull);

    viewModel.onMarkerFound('DemocritusAtomQ1W1');
    expect(viewModel.detectedLesson?.id, 'q1w1');

    viewModel.onMarkerFound('NameWithNoPattern');
    expect(viewModel.detectedLesson, isNull);
  });
}
