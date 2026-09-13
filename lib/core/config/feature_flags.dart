import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

class FeatureFlags {
  const FeatureFlags({
    this.newsEnabled = true,
    this.pollsEnabled = true,
  });

  final bool newsEnabled;
  final bool pollsEnabled;
}

final featureFlagsProvider =
    StateNotifierProvider<FeatureFlagsNotifier, FeatureFlags>((ref) {
  return FeatureFlagsNotifier();
});

class FeatureFlagsNotifier extends StateNotifier<FeatureFlags> {
  FeatureFlagsNotifier() : super(const FeatureFlags()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const {
        'feature_news_enabled': true,
        'feature_polls_enabled': true,
      });
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kReleaseMode ? const Duration(hours: 1) : Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();
      _apply(remoteConfig);

      remoteConfig.onConfigUpdated.listen((_) async {
        await remoteConfig.activate();
        _apply(remoteConfig);
      });
    } catch (error, stack) {
      appLogger.w('Remote Config unavailable, using defaults', error: error, stackTrace: stack);
    }
  }

  void _apply(FirebaseRemoteConfig remoteConfig) {
    state = FeatureFlags(
      newsEnabled: remoteConfig.getBool('feature_news_enabled'),
      pollsEnabled: remoteConfig.getBool('feature_polls_enabled'),
    );
  }
}
