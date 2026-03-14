import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;

class AdSenseWidget extends StatefulWidget {
  final String adSlot;
  const AdSenseWidget({super.key, required this.adSlot});

  @override
  State<AdSenseWidget> createState() => _AdSenseWidgetState();
}

class _AdSenseWidgetState extends State<AdSenseWidget> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();

    return Stack(
      children: [
        // AdSense HTML
        SizedBox(
          height: 90,
          width: double.infinity,
          child: HtmlElementView(
            viewType: 'adsense-${widget.adSlot}',
          ),
        ),

        // Big close button
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Container(
              width: 44,
              height: 44,
              color: Colors.black54,
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Register in main.dart:
void registerAdSenseViews() {
  if (!kIsWeb) return;

  final slots = ['dashboard_top', 'reports_top'];

  for (final slot in slots) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'adsense-$slot',
      (int viewId) {
        final container = html.DivElement()
          ..style.position = 'relative'
          ..style.width = '100%'
          ..style.height = '90px';

        final ins = html.Element.tag('ins')
          ..className = 'adsbygoogle'
          ..style.display = 'block'
          ..style.width = '100%'
          ..style.height = '90px'
          ..setAttribute('data-ad-client', 'ca-pub-XXXXXXXXXXXXXXXX')
          ..setAttribute('data-ad-slot', _getSlotId(slot))
          ..setAttribute('data-ad-format', 'horizontal');

        container.children.add(ins);

        html.document.body?.append(
          html.ScriptElement()
            ..text = '(adsbygoogle=window.adsbygoogle||[]).push({});'
        );

        return container;
      },
    );
  }
}

String _getSlotId(String slot) {
  const slots = {
    'dashboard_top': 'XXXXXXXXXX',
    'reports_top': 'XXXXXXXXXX',
  };
  return slots[slot] ?? '';
}
