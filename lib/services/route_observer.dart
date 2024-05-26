import 'package:flutter/material.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

mixin RouteObserved<T extends StatefulWidget> on State<T>, RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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

  void onEnter();

  void onLeave();
}
