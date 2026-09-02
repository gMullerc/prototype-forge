import 'package:flutter/material.dart';
import 'package:prototype_spec/prototype_spec.dart';

import 'flutter_prototype_catalog.dart';
import 'prototype_action_event.dart';

class PrototypeSurface extends StatelessWidget {
  const PrototypeSurface({
    super.key,
    required this.document,
    required this.catalog,
    this.onAction,
  });

  final PrototypeDocument document;
  final FlutterPrototypeCatalog catalog;
  final ValueChanged<PrototypeActionEvent>? onAction;

  @override
  Widget build(BuildContext context) {
    return _buildNode(context, document.screen.root);
  }

  Widget _buildNode(BuildContext context, PrototypeNode node) {
    final FlutterComponentFactory? factory = catalog.factoryFor(node.type);
    if (factory == null) {
      return _RenderFailure(
        message: 'Unknown component ${node.type}',
      );
    }

    try {
      return factory.builder(
        PrototypeRenderContext(
          buildChildren: () => <Widget>[
            for (final PrototypeNode child in node.children)
              _buildNode(context, child),
          ],
          dispatchAction: (PrototypeActionEvent event) {
            onAction?.call(event);
          },
        ),
        node,
      );
    } catch (error) {
      return _RenderFailure(
        message: 'Could not render ${node.type}: $error',
      );
    }
  }
}

class _RenderFailure extends StatelessWidget {
  const _RenderFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
