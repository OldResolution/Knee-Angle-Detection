import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_app/models/knee_data_point.dart';
import 'package:gopal_app/services/knee_analysis_service.dart';

void main() {
  test('emits threshold and sudden movement alerts with cooldown handling',
      () async {
    final controller = StreamController<KneeDataPoint>.broadcast();
    final service = KneeAnalysisService(
      dataStream: controller.stream,
      config: const AnalysisConfig(
        maxAngleThreshold: 100,
        minAngleThreshold: 20,
        suddenMovementThreshold: 150,
        cooldownDuration: Duration(seconds: 5),
      ),
    );

    final alerts = <String>[];
    final subscription = service.alertStream.listen((alert) {
      alerts.add(alert.title);
    });

    controller.add(
      KneeDataPoint(
        angle: 115,
        speed: 30,
        activityType: ActivityType.walking,
        timestamp: DateTime(2026, 1, 1, 10, 0, 0),
      ),
    );
    controller.add(
      KneeDataPoint(
        angle: 118,
        speed: 35,
        activityType: ActivityType.walking,
        timestamp: DateTime(2026, 1, 1, 10, 0, 2),
      ),
    );
    controller.add(
      KneeDataPoint(
        angle: 45,
        speed: 190,
        activityType: ActivityType.walking,
        timestamp: DateTime(2026, 1, 1, 10, 0, 3),
      ),
    );
    controller.add(
      KneeDataPoint(
        angle: 8,
        speed: 20,
        activityType: ActivityType.walking,
        timestamp: DateTime(2026, 1, 1, 10, 0, 8),
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(alerts, <String>[
      'Max Angle Exceeded',
      'Sudden Movement Detected',
      'Min Angle Breach',
    ]);

    await subscription.cancel();
    await service.dispose();
    await controller.close();
  });
}
