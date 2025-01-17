import 'package:logging_service/service/sensor_service.dart';

class ShakeService {
  final PhoneShakeCallback onPhoneShake;

  ShakeService({required this.onPhoneShake});

  ShakeDetector? shakeDetector;

  start() {
    shakeDetector = ShakeDetector.autoStart(onPhoneShake: onPhoneShake);
  }

  stop() {
    shakeDetector?.stopListening();
  }
}
