import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Command types for the overlay host
abstract class RiveOverlayCommand {}

class RiveOverlayShow extends RiveOverlayCommand {
  final String asset;
  final Alignment align;
  final Fit fit;
  final EdgeInsets? margin;
  final Duration? autoHideAfter;
  final int zone;

  RiveOverlayShow({
    required this.asset,
    this.align = Alignment.center,
    this.fit = Fit.contain,
    this.margin,
    this.autoHideAfter,
    this.zone = 2,
  });
}

class RiveOverlayHide extends RiveOverlayCommand {
  final int zone;
  RiveOverlayHide({this.zone = 2});
}

/// Service used to trigger global Rive overlays (e.g., achievements/trophies).
class RiveOverlayService {
  final _controller = StreamController<RiveOverlayCommand>.broadcast();

  Stream<RiveOverlayCommand> get commands => _controller.stream;

  void show({
    required String asset,
    Alignment align = Alignment.center,
    Fit fit = Fit.contain,
    EdgeInsets? margin,
    Duration? autoHideAfter,
    int zone = 2,
  }) {
    _controller.add(
      RiveOverlayShow(
        asset: asset,
        align: align,
        fit: fit,
        margin: margin,
        autoHideAfter: autoHideAfter,
        zone: zone,
      ),
    );
  }

  void hide({int zone = 2}) {
    _controller.add(RiveOverlayHide(zone: zone));
  }

  void dispose() {
    _controller.close();
  }
}
