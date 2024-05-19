import 'package:flutter/cupertino.dart';
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
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_left),
              ),
              Expanded(child: builder(context)),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ],
    );
  }
}
