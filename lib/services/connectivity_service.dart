import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_queue.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService._internal() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.firstOrNull ?? ConnectivityResult.none;
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Just came back online
        _controller.add(true);
        try {
          SyncQueue.instance.processQueue();
        } catch (_) {}
      } else if (wasOnline && !_isOnline) {
        // Just went offline
        _controller.add(false);
      }
    });
  }

  Future<void> initialize() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.firstOrNull ?? ConnectivityResult.none;
    _isOnline = result != ConnectivityResult.none;
    _controller.add(_isOnline);
  }
}
