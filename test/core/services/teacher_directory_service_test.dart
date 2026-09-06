import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/teacher_directory_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TeacherDirectoryService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = TeacherDirectoryService(firestore: firestore);
  });

  group('isAuthorizedTeacher', () {
    test('rejects an account that is not on the allowlist', () async {
      // This is the whole point of the allowlist: authenticating with some
      // arbitrary Google account must NOT grant teacher access. Before it
      // existed, any signed-in non-student email was treated as a teacher.
      expect(await service.isAuthorizedTeacher('stranger@gmail.com'), isFalse);
    });

    test('accepts an allowlisted account', () async {
      await service.addTeacher(
        email: 'maam.reyes@school.edu.ph',
        addedBy: kBootstrapTeacherEmail,
      );

      expect(
        await service.isAuthorizedTeacher('maam.reyes@school.edu.ph'),
        isTrue,
      );
    });

    test(
      'always accepts the bootstrap owner, even with no documents',
      () async {
        // There must always be a way back in if /teachers is empty or broken.
        expect(
          await service.isAuthorizedTeacher(kBootstrapTeacherEmail),
          isTrue,
        );
      },
    );

    test('is case-insensitive about the address', () async {
      await service.addTeacher(
        email: 'Maam.Reyes@School.edu.ph',
        addedBy: kBootstrapTeacherEmail,
      );

      expect(
        await service.isAuthorizedTeacher('maam.reyes@school.edu.ph'),
        isTrue,
      );
      expect(
        await service.isAuthorizedTeacher('MAAM.REYES@SCHOOL.EDU.PH'),
        isTrue,
      );
    });
  });

  group('addTeacher', () {
    test('refuses a student login', () async {
      // A student account must never be promotable to teacher.
      expect(
        () => service.addTeacher(
          email: '123456@arscience.school',
          addedBy: kBootstrapTeacherEmail,
        ),
        throwsArgumentError,
      );
    });

    test('refuses something that is not an email address', () async {
      expect(
        () => service.addTeacher(email: 'not-an-email', addedBy: 'x@y.com'),
        throwsArgumentError,
      );
    });

    test('refuses a duplicate with a message the teacher can act on', () async {
      await service.addTeacher(email: 'a@b.com', addedBy: 'x@y.com');

      expect(
        () => service.addTeacher(email: 'a@b.com', addedBy: 'x@y.com'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already has teacher access'),
          ),
        ),
      );
    });

    test('records who granted the access', () async {
      await service.addTeacher(email: 'a@b.com', addedBy: 'boss@school.ph');

      final doc = await firestore.collection('teachers').doc('a@b.com').get();
      expect(doc.data()!['addedBy'], 'boss@school.ph');
      expect(doc.data()!['addedAt'], isNotNull);
    });
  });

  group('removeTeacher', () {
    test('cannot remove the project owner', () async {
      expect(
        () => service.removeTeacher(
          email: kBootstrapTeacherEmail,
          requestedBy: 'someone@else.com',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cannot remove yourself', () async {
      // Removing your own access would eject you mid-session with no way
      // to undo it.
      await service.addTeacher(email: 'a@b.com', addedBy: 'x@y.com');

      expect(
        () => service.removeTeacher(email: 'a@b.com', requestedBy: 'A@B.com'),
        throwsA(isA<StateError>()),
      );
    });

    test('removes another teacher and revokes their access', () async {
      await service.addTeacher(email: 'a@b.com', addedBy: 'x@y.com');
      await service.removeTeacher(email: 'a@b.com', requestedBy: 'x@y.com');

      expect(await service.isAuthorizedTeacher('a@b.com'), isFalse);
    });
  });

  test('watchTeachers always includes the project owner', () async {
    final list = await service.watchTeachers().first;

    expect(list.map((t) => t.email), contains(kBootstrapTeacherEmail));
    expect(list.single.isBootstrap, isTrue);
  });
}
