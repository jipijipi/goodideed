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
  final Map<String, double>? bindings; // Data bindings by property name
  final bool useDataBinding;

  RiveOverlayShow({
    required this.asset,
    this.align = Alignment.center,
    this.fit = Fit.contain,
    this.margin,
    this.autoHideAfter,
    this.zone = 2,
    this.bindings,
    this.useDataBinding = false,
  });
}

class RiveOverlayHide extends RiveOverlayCommand {
  final int zone;
  RiveOverlayHide({this.zone = 2});
}

class RiveOverlayUpdate extends RiveOverlayCommand {
  final int zone;
  final Map<String, double> bindings;
  RiveOverlayUpdate({required this.zone, required this.bindings});
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
    Map<String, double>? bindings,
    bool useDataBinding = false,
  }) {
    _controller.add(
      RiveOverlayShow(
        asset: asset,
        align: align,
        fit: fit,
        margin: margin,
        autoHideAfter: autoHideAfter,
        zone: zone,
        bindings: bindings,
        useDataBinding: useDataBinding,
      ),
    );
  }

  void hide({int zone = 2}) {
    _controller.add(RiveOverlayHide(zone: zone));
  }

  void update({required int zone, required Map<String, double> bindings}) {
    _controller.add(RiveOverlayUpdate(zone: zone, bindings: bindings));
  }

  void dispose() {
    _controller.close();
  }
}
