import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prototype_interaction/prototype_interaction.dart';
import 'package:prototype_spec/prototype_spec.dart';

import 'flutter_prototype_catalog.dart';
import 'prototype_action_event.dart';
import 'prototype_surface_mode.dart';

class PrototypeSurface extends StatefulWidget {
  const PrototypeSurface({
    super.key,
    required this.document,
    required this.catalog,
    this.onAction,
    this.mode = PrototypeSurfaceMode.interactive,
    this.interactionController,
  });

  final PrototypeDocument document;
  final FlutterPrototypeCatalog catalog;
  final ValueChanged<PrototypeActionEvent>? onAction;
  final PrototypeSurfaceMode mode;
  final PrototypeInteractionController? interactionController;

  @override
  State<PrototypeSurface> createState() => _PrototypeSurfaceState();
}

class _PrototypeSurfaceState extends State<PrototypeSurface> {
  PrototypeInteractionController? _controller;
  StreamSubscription<PrototypeInteractionState>? _subscription;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant PrototypeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.interactionController != widget.interactionController) {
      _unbindController();
      _bindController();
    }
  }

  @override
  void dispose() {
    _unbindController();
    super.dispose();
  }

  void _bindController() {
    final PrototypeInteractionController? external =
        widget.interactionController;
    if (external != null) {
      _controller = external;
    } else if (widget.document.interaction != null) {
      _controller = PrototypeInteractionController(widget.document);
      _ownsController = true;
    }
    _subscription = _controller?.states.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _unbindController() {
    _subscription?.cancel();
    _subscription = null;
    if (_ownsController) _controller?.dispose();
    _controller = null;
    _ownsController = false;
  }

  @override
  Widget build(BuildContext context) {
    return _buildNode(context, widget.document.screen.root);
  }

  Widget _buildNode(BuildContext context, PrototypeNode node) {
    final PrototypeInteractionController? controller = _controller;
    if (widget.mode == PrototypeSurfaceMode.interactive &&
        controller != null &&
        !controller.isVisible(node)) {
      return const SizedBox.shrink();
    }

    final FlutterComponentFactory? factory =
        widget.catalog.factoryFor(node.type);
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
            PrototypeFeedback? feedback;
            if (widget.mode == PrototypeSurfaceMode.interactive &&
                controller != null) {
              final PrototypeActionResult result =
                  controller.dispatch(event.name);
              feedback = result.recognized
                  ? result.state.feedback
                  : PrototypeFeedback(
                      message:
                          'A ação "${event.name}" ainda não possui comportamento.',
                      tone: PrototypeFeedbackTone.warning,
                    );
            }
            widget.onAction?.call(event);
            if (feedback != null) _showFeedback(context, feedback);
          },
          mode: widget.mode,
          valueFor: (PrototypeNode target) =>
              controller?.valueFor(target) ?? target.props['value'],
          updateValue: (PrototypeNode target, Object? value) {
            if (widget.mode == PrototypeSurfaceMode.interactive) {
              controller?.setValueFor(target, value);
            }
          },
          errorFor: (PrototypeNode target) => controller?.errorFor(target),
          isSelected: (PrototypeNode target) =>
              controller?.isSelected(target) ?? false,
        ),
        node,
      );
    } catch (error) {
      return _RenderFailure(
        message: 'Could not render ${node.type}: $error',
      );
    }
  }

  void _showFeedback(BuildContext context, PrototypeFeedback feedback) {
    final Color background = switch (feedback.tone) {
      PrototypeFeedbackTone.success => const Color(0xFF176B51),
      PrototypeFeedbackTone.warning => const Color(0xFF8A5700),
      PrototypeFeedbackTone.error => Theme.of(context).colorScheme.error,
      PrototypeFeedbackTone.info => Theme.of(context).colorScheme.primary,
    };
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(feedback.message),
          backgroundColor: background,
        ),
      );
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
