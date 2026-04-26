import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, notDetermined }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  final connectivity = Connectivity();
  
  // Get initial status
  final initialResult = await connectivity.checkConnectivity();
  if (initialResult.contains(ConnectivityResult.none)) {
    yield ConnectivityStatus.isDisconnected;
  } else {
    yield ConnectivityStatus.isConnected;
  }

  // Listen for changes
  await for (final result in connectivity.onConnectivityChanged) {
    if (result.contains(ConnectivityResult.none)) {
      yield ConnectivityStatus.isDisconnected;
    } else {
      yield ConnectivityStatus.isConnected;
    }
  }
});
