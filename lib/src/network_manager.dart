import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;

  NetworkManager._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController.broadcast();

  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

    if (newStatus != _isOnline) {
      _isOnline = newStatus;
      _controller.add(_isOnline);
    }
  }
}
