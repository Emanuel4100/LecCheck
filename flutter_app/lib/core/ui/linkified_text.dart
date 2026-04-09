import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../util/open_url.dart';

/// Live linkified preview under a [TextEditingController] (e.g. notes fields).
class LinkifiedNotesPreview extends StatefulWidget {
  const LinkifiedNotesPreview({
    super.key,
    required this.controller,
    this.style,
  });

  final TextEditingController controller;
  final TextStyle? style;

  @override
  State<LinkifiedNotesPreview> createState() => _LinkifiedNotesPreviewState();
}

class _LinkifiedNotesPreviewState extends State<LinkifiedNotesPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant LinkifiedNotesPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.text.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LinkifiedText(
        text: t,
        style: widget.style ??
            Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        maxLines: 12,
        overflow: TextOverflow.fade,
      ),
    );
  }
}

/// Tappable URLs in plain text; uses theme link styling.
class LinkifiedText extends StatelessWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyMedium;
    final link = linkStyle ??
        base?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        );
    return Linkify(
      text: text,
      style: base,
      linkStyle: link,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign ?? TextAlign.start,
      onOpen: (link) {
        if (link is UrlElement) {
          tryLaunchLectureUrl(context, link.url);
        }
      },
    );
  }
}
