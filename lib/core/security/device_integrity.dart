import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freerasp/freerasp.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

const _compromisedKey = 'device_compromised';

class DeviceIntegrity extends ChangeNotifier {
  DeviceIntegrity._();

  static final DeviceIntegrity instance = DeviceIntegrity._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  bool _compromised = false;
  bool get isCompromised => _compromised;

  Future<void> initialize() async {
    final stored = await _storage.read(key: _compromisedKey);
    if (stored == 'true') {
      _compromised = true;
      await wipeTokens();
      notifyListeners();
    }

    try {
      await _startRasp();
    } catch (error, stack) {
      appLogger.e('Failed to start RASP', error: error, stackTrace: stack);
    }
  }

  Future<void> _startRasp() async {
    final callback = ThreatCallback(
      onPrivilegedAccess: () => _onCriticalThreat('privileged_access'),
      onHooks: () => _onCriticalThreat('hooks'),
      onAppIntegrity: () {
        if (kReleaseMode) {
          _onCriticalThreat('app_integrity');
        }
      },
      onSimulator: () {
        if (kReleaseMode) {
          _onCriticalThreat('simulator');
        }
      },
    );
    await Talsec.instance.attachListener(callback);

    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: AppConfig.androidPackageName,
        signingCertHashes: AppConfig.hasRaspSigningHash
            ? [AppConfig.androidSigningCertHash]
            : const ['AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='],
        supportedStores: const ['com.android.vending'],
      ),
      iosConfig: IOSConfig(
        bundleIds: [AppConfig.iosBundleId],
        teamId: AppConfig.iosTeamId.isEmpty ? 'XXXXXXXXXX' : AppConfig.iosTeamId,
      ),
      watcherMail: AppConfig.raspWatcherEmail,
      isProd: kReleaseMode && AppConfig.hasRaspSigningHash,
    );

    await Talsec.instance.start(config);
  }

  Future<void> _onCriticalThreat(String reason) async {
    appLogger.e('RASP blocked compromised device: $reason');
    if (!kReleaseMode) {
      return;
    }
    await markCompromised();
  }

  Future<void> markCompromised() async {
    _compromised = true;
    await _storage.write(key: _compromisedKey, value: 'true');
    await wipeTokens();
    notifyListeners();
  }

  Future<void> wipeTokens() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'biometric_email');
    await _storage.delete(key: 'biometric_password');
  }
}
