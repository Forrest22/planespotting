import 'package:flutter/material.dart';

/// An app bar title that shrinks to fit instead of being cut off, in the app bar's own text colour.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        // Taken from the app bar, since a plain text style would otherwise use the on-surface colour.
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: DefaultTextStyle.of(context).style.color),
      ),
    );
  }
}
