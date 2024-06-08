import 'package:flutter/material.dart';

final screenVisibilityRouteObserver = RouteObserver<ModalRoute<void>>();

mixin ScreenVisibility<T extends StatefulWidget>
    on State<T>, RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenVisibilityRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    screenVisibilityRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPush() {
    onEnter();
  }

  @override
  void didPop() {
    onLeave();
  }

  @override
  void didPushNext() {
    onLeave();
  }

  @override
  void didPopNext() {
    onEnter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.hidden:
        onLeave();
      case AppLifecycleState.resumed:
        // Ensure no popup or any overlay is showing
        if (ModalRoute.of(context)?.isCurrent == true) {
          onEnter();
        }
      default:
    }
  }

  void onEnter();

  void onLeave();
}
