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
  final Duration? minShowAfter;
  final int zone;
  final Map<String, double>? bindings; // Numeric bindings
  final Map<String, bool>? bindingsBool; // Boolean bindings
  final Map<String, String>? bindingsString; // String bindings
  final Map<String, int>? bindingsColor; // Color bindings (ARGB int)
  final bool useDataBinding;
  final String? id; // Optional overlay id for targeting and concurrency
  final String policy; // 'replace' | 'queue' | 'ignore'
  final int zIndex;

  RiveOverlayShow({
    required this.asset,
    this.align = Alignment.center,
    this.fit = Fit.contain,
    this.margin,
    this.autoHideAfter,
    this.minShowAfter,
    this.zone = 2,
    this.bindings,
    this.bindingsBool,
    this.bindingsString,
    this.bindingsColor,
    this.useDataBinding = false,
    this.id,
    this.policy = 'replace',
    this.zIndex = 0,
  });
}

class RiveOverlayHide extends RiveOverlayCommand {
  final int zone;
  final String? id; // If null, hide all in zone
  final bool all; // Hide all in zone
  RiveOverlayHide({this.zone = 2, this.id, this.all = false});
}

class RiveOverlayUpdate extends RiveOverlayCommand {
  final int zone;
  final Map<String, double>? bindings;
  final Map<String, bool>? bindingsBool;
  final Map<String, String>? bindingsString;
  final Map<String, int>? bindingsColor;
  final String? id;
  final Duration? autoHideAfter; // Optional: schedule hide after update
  RiveOverlayUpdate({
    required this.zone,
    this.bindings,
    this.bindingsBool,
    this.bindingsString,
    this.bindingsColor,
    this.id,
    this.autoHideAfter,
  });
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
    Duration? minShowAfter,
    int zone = 2,
    Map<String, double>? bindings,
    Map<String, bool>? bindingsBool,
    Map<String, String>? bindingsString,
    Map<String, int>? bindingsColor,
    bool useDataBinding = false,
    String? id,
    String policy = 'replace',
    int zIndex = 0,
  }) {
    _controller.add(
      RiveOverlayShow(
        asset: asset,
        align: align,
        fit: fit,
        margin: margin,
        autoHideAfter: autoHideAfter,
        minShowAfter: minShowAfter,
        zone: zone,
        bindings: bindings,
        bindingsBool: bindingsBool,
        bindingsString: bindingsString,
        bindingsColor: bindingsColor,
        useDataBinding: useDataBinding,
        id: id,
        policy: policy,
        zIndex: zIndex,
      ),
    );
  }

  void hide({int zone = 2, String? id, bool all = false}) {
    _controller.add(RiveOverlayHide(zone: zone, id: id, all: all));
  }

  void update({
    required int zone,
    Map<String, double>? bindings,
    Map<String, bool>? bindingsBool,
    Map<String, String>? bindingsString,
    Map<String, int>? bindingsColor,
    String? id,
    Duration? autoHideAfter,
  }) {
    _controller.add(
      RiveOverlayUpdate(
        zone: zone,
        bindings: bindings,
        bindingsBool: bindingsBool,
        bindingsString: bindingsString,
        bindingsColor: bindingsColor,
        id: id,
        autoHideAfter: autoHideAfter,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
