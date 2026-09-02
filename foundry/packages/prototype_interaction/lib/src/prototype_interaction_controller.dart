import 'dart:async';

import 'package:prototype_spec/prototype_spec.dart';

import 'prototype_interaction_state.dart';

typedef PrototypeClock = DateTime Function();

class PrototypeInteractionController {
  PrototypeInteractionController(
    this.document, {
    PrototypeClock? clock,
  }) : _clock = clock ?? DateTime.now {
    _initialValues = _collectInitialValues(document);
    _state = PrototypeInteractionState(values: _initialValues);
  }

  final PrototypeDocument document;
  final PrototypeClock _clock;
  final StreamController<PrototypeInteractionState> _states =
      StreamController<PrototypeInteractionState>.broadcast(sync: true);
  late final Map<String, Object?> _initialValues;
  late PrototypeInteractionState _state;
  bool _disposed = false;

  PrototypeInteractionState get state => _state;
  Stream<PrototypeInteractionState> get states => _states.stream;

  Object? valueFor(PrototypeNode node) {
    final String? key = node.interaction?.valueKey;
    if (key == null) return node.props['value'];
    return _state.values.containsKey(key)
        ? _state.values[key]
        : node.props['value'];
  }

  String? errorFor(PrototypeNode node) => _state.errors[node.id];

  bool isVisible(PrototypeNode node) => _matches(node.interaction?.visibleWhen);

  bool isSelected(PrototypeNode node) =>
      _matches(node.interaction?.selectedWhen);

  void setValueFor(PrototypeNode node, Object? value) {
    final String? key = node.interaction?.valueKey;
    if (key == null) return;
    setValue(key, value);
  }

  void setValue(String key, Object? value) {
    final Map<String, Object?> values = <String, Object?>{
      ..._state.values,
      key: value,
    };
    final Map<String, String> errors = <String, String>{..._state.errors};
    for (final PrototypeNode node in _nodes(document.screen.root)) {
      if (node.interaction?.valueKey == key) errors.remove(node.id);
    }
    _emit(
      PrototypeInteractionState(values: values, errors: errors),
    );
  }

  PrototypeActionResult dispatch(String actionName) {
    final PrototypeActionDefinition? action =
        document.interaction?.actionFor(actionName);
    if (action == null) {
      return PrototypeActionResult(
        recognized: false,
        validationPassed: true,
        state: _state,
      );
    }

    Map<String, Object?> values = <String, Object?>{..._state.values};
    Map<String, String> errors = <String, String>{..._state.errors};
    PrototypeFeedback? feedback;
    bool validationPassed = true;

    for (final PrototypeEffect effect in action.effects) {
      switch (effect.type) {
        case 'setValue':
          values[effect.key!] = effect.value;
          errors = _removeErrorsForKey(errors, effect.key!);
        case 'toggleValue':
          values[effect.key!] = !(values[effect.key!] as bool? ?? false);
          errors = _removeErrorsForKey(errors, effect.key!);
        case 'reset':
          values = <String, Object?>{..._initialValues};
          errors = <String, String>{};
        case 'validate':
          errors = _validate(values);
          validationPassed = errors.isEmpty;
          if (!validationPassed) {
            feedback = const PrototypeFeedback(
              message: 'Revise os campos destacados antes de continuar.',
              tone: PrototypeFeedbackTone.error,
            );
          }
        case 'showMessage':
          if (validationPassed) {
            feedback = PrototypeFeedback(
              message: effect.message!,
              tone: _tone(effect.tone),
            );
          }
      }
      if (!validationPassed) break;
    }

    _emit(
      PrototypeInteractionState(
        values: values,
        errors: errors,
        feedback: feedback,
      ),
    );
    return PrototypeActionResult(
      recognized: true,
      validationPassed: validationPassed,
      state: _state,
    );
  }

  void reset() {
    _emit(PrototypeInteractionState(values: _initialValues));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _states.close();
  }

  Map<String, String> _validate(Map<String, Object?> values) {
    final Map<String, String> errors = <String, String>{};
    for (final PrototypeNode node
        in _visibleNodes(document.screen.root, values)) {
      final PrototypeNodeInteraction? interaction = node.interaction;
      final String? key = interaction?.valueKey;
      if (interaction == null || key == null) {
        continue;
      }
      final Object? value =
          values.containsKey(key) ? values[key] : node.props['value'];
      if (interaction.required && _isEmpty(value)) {
        errors[node.id] = 'Campo obrigatório.';
        continue;
      }
      if (_isEmpty(value)) continue;
      for (final PrototypeValidationRule rule in interaction.validations) {
        final String? message = _validationMessage(rule, value);
        if (message != null) {
          errors[node.id] = message;
          break;
        }
      }
    }
    return errors;
  }

  String? _validationMessage(PrototypeValidationRule rule, Object? value) {
    final String text = value.toString().trim();
    return switch (rule.type) {
      'cpf' => _isValidCpf(text) ? null : 'Informe um CPF válido.',
      'cnpj' => _isValidCnpj(text) ? null : 'Informe um CNPJ válido.',
      'minAge' => _hasMinimumAge(text, (rule.value as num).toInt())
          ? null
          : 'A pessoa deve ter pelo menos ${(rule.value as num).toInt()} anos.',
      _ => null,
    };
  }

  Map<String, String> _removeErrorsForKey(
    Map<String, String> errors,
    String key,
  ) {
    final Map<String, String> next = <String, String>{...errors};
    for (final PrototypeNode node in _nodes(document.screen.root)) {
      if (node.interaction?.valueKey == key) next.remove(node.id);
    }
    return next;
  }

  bool _matches(PrototypeStateCondition? condition) =>
      _matchesWith(condition, _state.values);

  bool _matchesWith(
    PrototypeStateCondition? condition,
    Map<String, Object?> values,
  ) {
    if (condition == null) return true;
    return values[condition.key] == condition.equals;
  }

  void _emit(PrototypeInteractionState state) {
    if (_disposed) return;
    _state = state;
    _states.add(state);
  }

  static Map<String, Object?> _collectInitialValues(
    PrototypeDocument document,
  ) {
    final Map<String, Object?> result = <String, Object?>{
      ...?document.interaction?.initialState,
    };
    for (final PrototypeNode node in _nodes(document.screen.root)) {
      final String? key = node.interaction?.valueKey;
      if (key != null && !result.containsKey(key)) {
        result[key] = node.props['value'];
      }
    }
    return result;
  }

  static Iterable<PrototypeNode> _nodes(PrototypeNode root) sync* {
    yield root;
    for (final PrototypeNode child in root.children) {
      yield* _nodes(child);
    }
  }

  static Iterable<PrototypeNode> _visibleNodes(
    PrototypeNode root,
    Map<String, Object?> values,
  ) sync* {
    final PrototypeStateCondition? condition = root.interaction?.visibleWhen;
    if (condition != null && values[condition.key] != condition.equals) return;
    yield root;
    for (final PrototypeNode child in root.children) {
      yield* _visibleNodes(child, values);
    }
  }

  static bool _isEmpty(Object? value) =>
      value == null || (value is String && value.trim().isEmpty);

  bool _hasMinimumAge(String value, int minimumAge) {
    final DateTime? birthDate = _parseDate(value);
    if (birthDate == null) return false;
    final DateTime now = _clock();
    final DateTime threshold = DateTime(
      now.year - minimumAge,
      now.month,
      now.day,
    );
    return !birthDate.isAfter(threshold);
  }

  static DateTime? _parseDate(String value) {
    final DateTime? iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final RegExpMatch? match =
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    if (match == null) return null;
    final int day = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int year = int.parse(match.group(3)!);
    final DateTime date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static bool _isValidCpf(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || RegExp(r'^(\d)\1+$').hasMatch(digits)) {
      return false;
    }
    int digit(int length, int factor) {
      int total = 0;
      for (int index = 0; index < length; index++) {
        total += int.parse(digits[index]) * factor--;
      }
      final int remainder = total % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    return digit(9, 10) == int.parse(digits[9]) &&
        digit(10, 11) == int.parse(digits[10]);
  }

  static bool _isValidCnpj(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14 || RegExp(r'^(\d)\1+$').hasMatch(digits)) {
      return false;
    }
    int digit(int length, List<int> factors) {
      int total = 0;
      for (int index = 0; index < length; index++) {
        total += int.parse(digits[index]) * factors[index];
      }
      final int remainder = total % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    const List<int> first = <int>[5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const List<int> second = <int>[6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return digit(12, first) == int.parse(digits[12]) &&
        digit(13, second) == int.parse(digits[13]);
  }

  static PrototypeFeedbackTone _tone(String? value) => switch (value) {
        'success' => PrototypeFeedbackTone.success,
        'warning' => PrototypeFeedbackTone.warning,
        'error' => PrototypeFeedbackTone.error,
        _ => PrototypeFeedbackTone.info,
      };
}
