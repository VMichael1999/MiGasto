import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/setup_issues.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);

  List<SetupIssue> issues({
    bool isAndroid = true,
    bool notifications = true,
    bool battery = true,
    DateTime? dismissed,
  }) =>
      computeSetupIssues(
        isAndroid: isAndroid,
        notificationsOn: notifications,
        batteryUnrestricted: battery,
        batteryDismissedAt: dismissed,
        now: now,
      );

  test('todo en orden: no hay avisos', () {
    expect(issues(), isEmpty);
  });

  test('en iPhone nunca hay avisos', () {
    expect(issues(isAndroid: false, notifications: false, battery: false), isEmpty);
  });

  test('lectura apagada es lo primero', () {
    expect(issues(notifications: false, battery: false),
        [SetupIssue.lecturaApagada, SetupIssue.bateriaRestringida]);
    expect(issues(notifications: false), [SetupIssue.lecturaApagada]);
  });

  test('batería restringida avisa solo si la lectura está encendida', () {
    expect(issues(battery: false), [SetupIssue.bateriaRestringida]);
  });

  test('"Ahora no" esconde el aviso de batería por 7 días y luego vuelve', () {
    expect(issues(battery: false, dismissed: now.subtract(const Duration(days: 3))), isEmpty);
    expect(issues(battery: false, dismissed: now.subtract(const Duration(days: 8))),
        [SetupIssue.bateriaRestringida]);
  });

  test('"Ahora no" no esconde que la lectura esté apagada', () {
    expect(
      issues(notifications: false, battery: false, dismissed: now.subtract(const Duration(days: 1))),
      [SetupIssue.lecturaApagada],
    );
  });
}
