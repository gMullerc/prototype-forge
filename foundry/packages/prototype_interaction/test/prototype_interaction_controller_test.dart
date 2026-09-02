import 'package:prototype_interaction/prototype_interaction.dart';
import 'package:prototype_spec/prototype_spec.dart';
import 'package:test/test.dart';

void main() {
  final PrototypeDocument document = const PrototypeSpecDecoder().decode('''
{
  "specVersion": "1.1",
  "interaction": {
    "initialState": {"employee": false, "cpf": "", "birth": "", "cnpj": ""},
    "actions": [
      {"name": "employee_yes", "effects": [{"type": "setValue", "key": "employee", "value": true}]},
      {"name": "employee_no", "effects": [{"type": "setValue", "key": "employee", "value": false}]},
      {"name": "save", "effects": [{"type": "validate"}, {"type": "showMessage", "tone": "success", "message": "Cadastro salvo."}]},
      {"name": "cancel", "effects": [{"type": "reset"}]}
    ]
  },
  "screen": {
    "id": "person",
    "title": "Cadastro",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {"id": "cpf", "type": "TextField", "interaction": {"valueKey": "cpf", "required": true, "validations": [{"type": "cpf"}]}},
        {"id": "birth", "type": "TextField", "interaction": {"valueKey": "birth", "required": true, "validations": [{"type": "minAge", "value": 18}]}},
        {"id": "employee-fields", "type": "Column", "interaction": {"visibleWhen": {"key": "employee", "equals": true}}, "children": [
          {"id": "cnpj", "type": "TextField", "interaction": {"valueKey": "cnpj", "required": true, "validations": [{"type": "cnpj"}]}}
        ]},
        {"id": "save", "type": "Button", "props": {"action": "save"}}
      ]
    }
  }
}
''');

  test('updates state and evaluates conditional visibility', () {
    final PrototypeInteractionController controller =
        PrototypeInteractionController(document);
    addTearDown(controller.dispose);
    final PrototypeNode employeeFields =
        document.screen.root.children.elementAt(2);

    expect(controller.isVisible(employeeFields), isFalse);
    controller.dispatch('employee_yes');
    expect(controller.state.values['employee'], isTrue);
    expect(controller.isVisible(employeeFields), isTrue);
    controller.dispatch('employee_no');
    expect(controller.isVisible(employeeFields), isFalse);
  });

  test('validates CPF, age and conditional CNPJ before success', () {
    final PrototypeInteractionController controller =
        PrototypeInteractionController(
      document,
      clock: () => DateTime(2026, 9, 2),
    );
    addTearDown(controller.dispose);

    controller.dispatch('employee_yes');
    PrototypeActionResult result = controller.dispatch('save');
    expect(result.validationPassed, isFalse);
    expect(controller.state.errors.keys,
        containsAll(<String>['cpf', 'birth', 'cnpj']));

    controller.setValue('cpf', '529.982.247-25');
    controller.setValue('birth', '01/01/2000');
    controller.setValue('cnpj', '04.252.011/0001-10');
    result = controller.dispatch('save');

    expect(result.validationPassed, isTrue);
    expect(controller.state.errors, isEmpty);
    expect(controller.state.feedback?.message, 'Cadastro salvo.');
    expect(controller.state.feedback?.tone, PrototypeFeedbackTone.success);
  });

  test('does not validate hidden conditional fields and can reset state', () {
    final PrototypeInteractionController controller =
        PrototypeInteractionController(
      document,
      clock: () => DateTime(2026, 9, 2),
    );
    addTearDown(controller.dispose);
    controller.setValue('cpf', '52998224725');
    controller.setValue('birth', '2000-01-01');

    final PrototypeActionResult result = controller.dispatch('save');
    expect(result.validationPassed, isTrue);
    expect(controller.state.errors, isNot(contains('cnpj')));

    controller.dispatch('employee_yes');
    controller.dispatch('cancel');
    expect(controller.state.values['employee'], isFalse);
    expect(controller.state.values['cpf'], '');
  });
}
