import 'package:flutter/material.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

mixin RouteObserved<T extends StatefulWidget>
    on State<T>, RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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
        onEnter();
      default:
    }
  }

  void onEnter();

  void onLeave();
}
