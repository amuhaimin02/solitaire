import 'package:flutter/material.dart';

class Pager extends StatelessWidget {
  const Pager({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_left),
              ),
              Flexible(child: builder(context)),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: SizedBox.expand(),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
