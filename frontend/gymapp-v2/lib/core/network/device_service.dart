import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Cihazın benzersiz kimliğini (Device ID) yönetir.
/// Donanım seviyesinde şifreli alanda saklanır.
class DeviceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: 'device_id');

    if (deviceId == null) {
      // Yeni bir benzersiz cihaz kimliği üret ve sakla
      deviceId = _uuid.v4();
      await _storage.write(key: 'device_id', value: deviceId);
    }

    return deviceId;
  }
}
