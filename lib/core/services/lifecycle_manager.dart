import 'package:flutter/widgets.dart';

abstract class AppLifecycleListenerDelegate {
  void onAppPaused();
  void onAppResumed();
  void onAppInactive();
}

class AppLifecycleManager with WidgetsBindingObserver {
  final List<AppLifecycleListenerDelegate> _delegates = [];

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _delegates.clear();
  }

  void addDelegate(AppLifecycleListenerDelegate delegate) {
    if (!_delegates.contains(delegate)) {
      _delegates.add(delegate);
    }
  }

  void removeDelegate(AppLifecycleListenerDelegate delegate) {
    _delegates.remove(delegate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        for (final delegate in _delegates) {
          delegate.onAppPaused();
        }
        break;
      case AppLifecycleState.resumed:
        for (final delegate in _delegates) {
          delegate.onAppResumed();
        }
        break;
      case AppLifecycleState.inactive:
        for (final delegate in _delegates) {
          delegate.onAppInactive();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
