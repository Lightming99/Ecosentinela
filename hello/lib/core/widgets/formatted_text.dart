// lib/core/widgets/formatted_text.dart

import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String data; // message text
  final TextStyle? style; // optional style from parent

  const FormattedText({
    Key? key,
    required this.data,
    this.style,
  }) : super(key: key);

  List<TextSpan> _parseText(String input) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*'); // matches **bold**
    int start = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: input.substring(start, match.start),
          style: style, // apply base style
        ));
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: (style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = match.end;
    }

    if (start < input.length) {
      spans.add(TextSpan(
        text: input.substring(start),
        style: style,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: style ??
            TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
        children: _parseText(data),
      ),
      textAlign: TextAlign.start,
    );
  }
}
