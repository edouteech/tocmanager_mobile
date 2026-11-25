import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

class NetworkService {
  static final NetworkService _instance = NetworkService._();
  static NetworkService get instance => _instance;
  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = false;
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  StreamSubscription? _sub;
  Future<void>? _initFuture;

  Future<void> initialize() => ensureInitialized();

  Future<void> ensureInitialized() => _initFuture ??= _doInitialize();

  Future<void> _doInitialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = await _checkRealInternet(results);
      if (!_controller.isClosed) {
        _controller.add(_isOnline);
      }

      _sub ??= _connectivity.onConnectivityChanged.listen((results) async {
        final online = await _checkRealInternet(results);
        if (online != _isOnline) {
          _isOnline = online;
          if (!_controller.isClosed) {
            _controller.add(_isOnline);
          }
        }
      });
    } catch (_) {
      // Connectivity plugin may be unavailable in headless tests.
    }
  }

  @visibleForTesting
  void setOnlineForTesting(bool online) {
    _initFuture ??= Future<void>.value();
    _isOnline = online;
    if (!_controller.isClosed) {
      _controller.add(_isOnline);
    }
  }

  Future<bool> _checkRealInternet(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Local network fallback test (e.g. localhost or custom server)
      return true;
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
