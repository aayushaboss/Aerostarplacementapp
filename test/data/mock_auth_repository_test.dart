import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerostar_edge/data/repositories/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockAuthRepository();
  });

  test('verifyOtp rejects a wrong code', () async {
    await repo.requestOtp('9999999999');
    await expectLater(
      repo.verifyOtp('9999999999', '000000'),
      throwsA(predicate((e) => e.toString().contains('otp_invalid'))),
    );
  });

  test('verifyOtp accepts the demo code and creates a fresh user for a new signup', () async {
    await repo.requestOtp('9999999999');
    final user = await repo.verifyOtp('9999999999', MockAuthRepository.demoOtpCode);

    expect(user.identifier, '9999999999');
    expect(user.onboardingComplete, isFalse);
    expect(user.phone, '9999999999');
  });

  test('a returning login resumes a completed profile; a non-returning signup never does', () async {
    await repo.requestOtp('someone@example.com');
    final first = await repo.verifyOtp('someone@example.com', MockAuthRepository.demoOtpCode);
    final completed = await repo.updateProfile(first, (u) => u.copyWith(onboardingComplete: true, name: 'Someone'));
    expect(completed.onboardingComplete, isTrue);

    await repo.requestOtp('someone@example.com');
    final returning = await repo.verifyOtp('someone@example.com', MockAuthRepository.demoOtpCode, returning: true);
    expect(returning.id, first.id);
    expect(returning.onboardingComplete, isTrue);
    expect(returning.name, 'Someone');

    // Per AppState/MockAuthRepository's own documented behavior: a
    // non-returning signup must never silently resume a previously
    // completed profile, even for the same identifier.
    await repo.requestOtp('someone@example.com');
    final freshSignup = await repo.verifyOtp('someone@example.com', MockAuthRepository.demoOtpCode);
    expect(freshSignup.onboardingComplete, isFalse);
  });

  test('findAccountByIdentifier finds a previously-created account', () async {
    await repo.requestOtp('lookup@example.com');
    final created = await repo.verifyOtp('lookup@example.com', MockAuthRepository.demoOtpCode);

    final found = await repo.findAccountByIdentifier('lookup@example.com');
    expect(found?.id, created.id);
  });

  test('findAccountByIdentifier returns null for an identifier that never signed up', () async {
    final found = await repo.findAccountByIdentifier('nobody@example.com');
    expect(found, isNull);
  });
}
