// lib/widgets/connectivity_banner.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final isOffline = !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.wifi);
      if (isOffline != _isOffline) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = !connectivityResult.contains(ConnectivityResult.mobile) &&
          !connectivityResult.contains(ConnectivityResult.wifi);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.red.shade700,
            child: const Text(
              'You are offline',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}