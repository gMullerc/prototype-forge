import 'package:flutter/widgets.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_spec/prototype_spec.dart';

import 'prototype_action_event.dart';
import 'prototype_surface_mode.dart';

typedef PrototypeActionCallback = void Function(PrototypeActionEvent event);
typedef PrototypeWidgetBuilder = Widget Function(
  PrototypeRenderContext context,
  PrototypeNode node,
);

class PrototypeRenderContext {
  const PrototypeRenderContext({
    required this.buildChildren,
    required this.dispatchAction,
    required this.mode,
    required this.valueFor,
    required this.updateValue,
    required this.errorFor,
    required this.isSelected,
  });

  final List<Widget> Function() buildChildren;
  final PrototypeActionCallback dispatchAction;
  final PrototypeSurfaceMode mode;
  final Object? Function(PrototypeNode node) valueFor;
  final void Function(PrototypeNode node, Object? value) updateValue;
  final String? Function(PrototypeNode node) errorFor;
  final bool Function(PrototypeNode node) isSelected;

  bool get isInteractive => mode == PrototypeSurfaceMode.interactive;
}

class FlutterComponentFactory {
  const FlutterComponentFactory({
    required this.contract,
    required this.builder,
  });

  final ComponentContract contract;
  final PrototypeWidgetBuilder builder;
}

class FlutterPrototypeCatalog {
  FlutterPrototypeCatalog(Iterable<FlutterComponentFactory> factories)
      : _factories = <String, FlutterComponentFactory>{
          for (final FlutterComponentFactory factory in factories)
            factory.contract.type: factory,
        },
        runtimeCatalog = PrototypeCatalog(
          factories.map(
            (FlutterComponentFactory factory) => factory.contract,
          ),
        );

  final Map<String, FlutterComponentFactory> _factories;
  final PrototypeCatalog runtimeCatalog;

  FlutterComponentFactory? factoryFor(String type) => _factories[type];
}
