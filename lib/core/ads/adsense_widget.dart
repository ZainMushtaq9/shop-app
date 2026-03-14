import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// AdSense widget — currently stubbed out.
/// Will be enabled once AdSense account is approved.
/// The actual HTML ad integration requires `package:web` which
/// will be added when the AdSense publisher ID is ready.
class AdSenseWidget extends StatefulWidget {
  final String adSlot;
  const AdSenseWidget({super.key, required this.adSlot});

  @override
  State<AdSenseWidget> createState() => _AdSenseWidgetState();
}

class _AdSenseWidgetState extends State<AdSenseWidget> {
  @override
  Widget build(BuildContext context) {
    // AdSense not yet configured — return empty
    return const SizedBox.shrink();
  }
}

/// Stub registration — no-op until AdSense is configured
void registerAdSenseViews() {
  // Will be implemented when AdSense publisher ID is available
}
