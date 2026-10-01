import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/setup_issues.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);

  List<SetupIssue> issues({
    bool isAndroid = true,
    bool notifications = true,
    bool battery = true,
    bool alerts = true,
    DateTime? dismissed,
    DateTime? alertsDismissed,
  }) =>
      computeSetupIssues(
        isAndroid: isAndroid,
        notificationsOn: notifications,
        batteryUnrestricted: battery,
        alertsOn: alerts,
        alertsDismissedAt: alertsDismissed,
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

  test('avisos de notificaciones apagados: salen si la lectura está encendida', () {
    expect(issues(alerts: false), [SetupIssue.avisosApagados]);
    expect(issues(alerts: false, battery: false),
        [SetupIssue.avisosApagados, SetupIssue.bateriaRestringida]);
  });

  test('sin la lectura encendida, primero va ese aviso y no el de las notificaciones propias', () {
    expect(issues(notifications: false, alerts: false), [SetupIssue.lecturaApagada]);
  });

  test('"Ahora no" en los avisos los esconde 7 días, aparte del de batería', () {
    expect(issues(alerts: false, alertsDismissed: now.subtract(const Duration(days: 2))), isEmpty);
    expect(issues(alerts: false, alertsDismissed: now.subtract(const Duration(days: 9))),
        [SetupIssue.avisosApagados]);
    expect(
      issues(alerts: false, battery: false, alertsDismissed: now.subtract(const Duration(days: 2))),
      [SetupIssue.bateriaRestringida],
    );
  });
}
