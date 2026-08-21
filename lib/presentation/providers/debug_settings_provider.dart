import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/mock_data_source.dart';

class DebugSettingsState {
  final bool simulate404;
  final bool simulateTimeout;
  final bool simulateValidationError;
  final bool simulateOffline;
  final int artificialDelayMs;

  const DebugSettingsState({
    this.simulate404 = false,
    this.simulateTimeout = false,
    this.simulateValidationError = false,
    this.simulateOffline = false,
    this.artificialDelayMs = 400,
  });

  DebugSettingsState copyWith({
    bool? simulate404,
    bool? simulateTimeout,
    bool? simulateValidationError,
    bool? simulateOffline,
    int? artificialDelayMs,
  }) {
    return DebugSettingsState(
      simulate404: simulate404 ?? this.simulate404,
      simulateTimeout: simulateTimeout ?? this.simulateTimeout,
      simulateValidationError: simulateValidationError ?? this.simulateValidationError,
      simulateOffline: simulateOffline ?? this.simulateOffline,
      artificialDelayMs: artificialDelayMs ?? this.artificialDelayMs,
    );
  }
}

class DebugSettingsNotifier extends StateNotifier<DebugSettingsState> {
  final MockDataSource _mockDataSource;

  DebugSettingsNotifier(this._mockDataSource) : super(const DebugSettingsState());

  void toggle404(bool value) {
    _mockDataSource.simulate404 = value;
    state = state.copyWith(simulate404: value);
  }

  void toggleTimeout(bool value) {
    _mockDataSource.simulateTimeout = value;
    state = state.copyWith(simulateTimeout: value);
  }

  void toggleValidationError(bool value) {
    _mockDataSource.simulateValidationError = value;
    state = state.copyWith(simulateValidationError: value);
  }

  void toggleOffline(bool value) {
    _mockDataSource.simulateOffline = value;
    state = state.copyWith(simulateOffline: value);
  }

  void setDelay(int delayMs) {
    _mockDataSource.artificialDelayMs = delayMs;
    state = state.copyWith(artificialDelayMs: delayMs);
  }
}

final mockDataSourceProvider = Provider<MockDataSource>((ref) {
  return MockDataSource();
});

final debugSettingsProvider = StateNotifierProvider<DebugSettingsNotifier, DebugSettingsState>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  return DebugSettingsNotifier(mockDs);
});
