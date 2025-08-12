import 'package:flutter/material.dart';
import 'package:noexc/services/rive_overlay_service.dart';

import 'rive_overlay_host.dart';

/// Hosts Rive overlay zones that should appear behind content but under messages (zone 3).
class RiveOverlayLayerBehindUI extends StatelessWidget {
  final RiveOverlayService service;

  const RiveOverlayLayerBehindUI({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return RiveOverlayHost(
      key: const ValueKey('rive_overlay_zone_3'),
      service: service,
      zone: 3,
    );
  }
}

/// Hosts Rive overlay zones that should appear above messages but beneath UI (zone 4).
class RiveOverlayLayerMidUI extends StatelessWidget {
  final RiveOverlayService service;

  const RiveOverlayLayerMidUI({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return RiveOverlayHost(
      key: const ValueKey('rive_overlay_zone_4'),
      service: service,
      zone: 4,
    );
  }
}

/// Hosts Rive overlay zones that should appear above UI (zone 2).
class RiveOverlayLayerFrontUI extends StatelessWidget {
  final RiveOverlayService service;

  const RiveOverlayLayerFrontUI({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return RiveOverlayHost(
      key: const ValueKey('rive_overlay_zone_2'),
      service: service,
      zone: 2,
    );
  }
}
