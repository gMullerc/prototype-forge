import 'dart:convert';

import 'package:prototype_agent/prototype_agent.dart';

import 'local_prototype_scenarios.dart';

class LocalPrototypeAgent
    implements PrototypeAgent, PrototypeConversationalAgent {
  LocalPrototypeAgent({LocalPrototypeScenarioRegistry? scenarioRegistry}) {
    _scenarioRegistry = scenarioRegistry ??
        LocalPrototypeScenarioRegistry(
          scenarios: <LocalPrototypeScenario>[
            LocalPrototypeScenario(
              id: 'receipt',
              keywords: const <String>['pagamento', 'comprovante'],
              builder: (_) => _receiptDocument(),
            ),
            LocalPrototypeScenario(
              id: 'login',
              keywords: const <String>['login', 'acesso', 'senha'],
              builder: (_) => _loginDocument(),
            ),
            LocalPrototypeScenario(
              id: 'bank-home',
              keywords: const <String>['banco', 'saldo', 'conta'],
              builder: (_) => _bankHomeDocument(),
            ),
            LocalPrototypeScenario(
              id: 'person-registration',
              keywords: const <String>['cadastro de pessoas', 'cpf', 'cnpj'],
              builder: (_) => _personRegistrationDocument(),
            ),
          ],
          fallback: _discoveryDocument,
        );
  }

  late final LocalPrototypeScenarioRegistry _scenarioRegistry;

  @override
  String get id => 'local-contract';

  @override
  String get label => 'Motor local';

  @override
  Future<String> generate(PrototypeBrief brief) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return jsonEncode(_scenarioRegistry.build(brief.text));
  }

  @override
  Future<PrototypeAgentTurn> respond(PrototypeBrief brief) async {
    return PrototypeAgentTurn.contract(document: await generate(brief));
  }

  Map<String, Object?> _loginDocument() => <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{
          'id': 'bank-login',
          'title': 'Acesso à conta',
          'root': <String, Object?>{
            'id': 'root',
            'type': 'Column',
            'props': <String, Object?>{'gap': 18, 'align': 'stretch'},
            'children': <Object?>[
              <String, Object?>{
                'id': 'welcome-row',
                'type': 'Row',
                'props': <String, Object?>{'gap': 12},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'brand-avatar',
                    'type': 'Avatar',
                    'props': <String, Object?>{
                      'name': 'Conta Aurora',
                      'initials': 'A',
                      'tone': 'brand',
                    },
                  },
                  <String, Object?>{
                    'id': 'welcome-copy',
                    'type': 'Column',
                    'props': <String, Object?>{'gap': 4},
                    'children': <Object?>[
                      <String, Object?>{
                        'id': 'welcome-title',
                        'type': 'Text',
                        'props': <String, Object?>{
                          'text': 'Olá, que bom ter você aqui',
                          'variant': 'title',
                        },
                      },
                      <String, Object?>{
                        'id': 'welcome-caption',
                        'type': 'Text',
                        'props': <String, Object?>{
                          'text': 'Entre para acompanhar sua conta.',
                          'variant': 'body',
                          'tone': 'muted',
                        },
                      },
                    ],
                  },
                ],
              },
              <String, Object?>{
                'id': 'security-notice',
                'type': 'Notice',
                'props': <String, Object?>{
                  'title': 'Acesso seguro',
                  'message': 'Nunca compartilharemos sua senha por mensagem.',
                  'tone': 'info',
                  'icon': 'lock',
                },
              },
              <String, Object?>{
                'id': 'email-field',
                'type': 'TextField',
                'props': <String, Object?>{
                  'label': 'E-mail',
                  'placeholder': 'voce@exemplo.com',
                  'keyboard': 'email',
                },
              },
              <String, Object?>{
                'id': 'password-field',
                'type': 'TextField',
                'props': <String, Object?>{
                  'label': 'Senha',
                  'placeholder': 'Digite sua senha',
                  'keyboard': 'password',
                },
              },
              <String, Object?>{
                'id': 'login-action',
                'type': 'Button',
                'props': <String, Object?>{
                  'label': 'Entrar',
                  'action': 'login',
                  'style': 'primary',
                  'icon': 'arrow',
                },
              },
              <String, Object?>{
                'id': 'forgot-password',
                'type': 'Button',
                'props': <String, Object?>{
                  'label': 'Esqueci minha senha',
                  'action': 'recover_password',
                  'style': 'quiet',
                },
              },
            ],
          },
        },
      };

  Map<String, Object?> _bankHomeDocument() => <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{
          'id': 'bank-home',
          'title': 'Início da conta',
          'root': <String, Object?>{
            'id': 'root',
            'type': 'Column',
            'props': <String, Object?>{'gap': 18, 'align': 'stretch'},
            'children': <Object?>[
              <String, Object?>{
                'id': 'account-header',
                'type': 'Row',
                'props': <String, Object?>{'gap': 12},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'customer-avatar',
                    'type': 'Avatar',
                    'props': <String, Object?>{
                      'name': 'Marina Souza',
                      'initials': 'MS',
                      'tone': 'success',
                    },
                  },
                  <String, Object?>{
                    'id': 'account-greeting',
                    'type': 'Column',
                    'props': <String, Object?>{'gap': 4},
                    'children': <Object?>[
                      <String, Object?>{
                        'id': 'greeting',
                        'type': 'Text',
                        'props': <String, Object?>{
                          'text': 'Bom dia, Marina',
                          'variant': 'title',
                        },
                      },
                      <String, Object?>{
                        'id': 'account-type',
                        'type': 'Text',
                        'props': <String, Object?>{
                          'text': 'Conta pessoal · final 2048',
                          'variant': 'caption',
                          'tone': 'muted',
                        },
                      },
                    ],
                  },
                  <String, Object?>{
                    'id': 'account-status',
                    'type': 'Badge',
                    'props': <String, Object?>{
                      'label': 'Ativa',
                      'tone': 'success',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'balance-card',
                'type': 'Card',
                'props': <String, Object?>{
                  'tone': 'emphasis',
                  'padding': 22,
                },
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'balance-label',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Saldo disponível',
                      'variant': 'caption',
                      'tone': 'muted',
                    },
                  },
                  <String, Object?>{
                    'id': 'balance-value',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'R\$ 8.450,32',
                      'variant': 'display',
                    },
                  },
                  <String, Object?>{
                    'id': 'balance-visibility',
                    'type': 'Button',
                    'props': <String, Object?>{
                      'label': 'Ocultar saldo',
                      'action': 'toggle_balance',
                      'style': 'quiet',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'metrics',
                'type': 'Row',
                'props': <String, Object?>{'gap': 12},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'credit-metric',
                    'type': 'Metric',
                    'props': <String, Object?>{
                      'label': 'Cartão de crédito',
                      'value': 'R\$ 2.180,00',
                      'trend': 'Disponível para uso',
                      'tone': 'success',
                    },
                  },
                  <String, Object?>{
                    'id': 'invoice-metric',
                    'type': 'Metric',
                    'props': <String, Object?>{
                      'label': 'Próxima fatura',
                      'value': 'R\$ 640,80',
                      'trend': 'Vence em 12 dias',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'recent-title',
                'type': 'Text',
                'props': <String, Object?>{
                  'text': 'Movimentações recentes',
                  'variant': 'title',
                },
              },
              <String, Object?>{
                'id': 'recent-list',
                'type': 'List',
                'props': <String, Object?>{'gap': 2},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'marketplace-purchase',
                    'type': 'ListItem',
                    'props': <String, Object?>{
                      'label': 'Mercado Aurora',
                      'supporting': 'Hoje · Cartão de débito',
                      'trailing': '- R\$ 128,40',
                      'icon': 'wallet',
                      'action': 'open_transaction',
                    },
                  },
                  <String, Object?>{
                    'id': 'salary-credit',
                    'type': 'ListItem',
                    'props': <String, Object?>{
                      'label': 'Salário',
                      'supporting': 'Ontem · Transferência recebida',
                      'trailing': '+ R\$ 6.500,00',
                      'icon': 'arrow',
                      'action': 'open_transaction',
                    },
                  },
                ],
              },
            ],
          },
        },
      };

  Map<String, Object?> _receiptDocument() => <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{
          'id': 'payment-receipt',
          'title': 'Comprovante de pagamento',
          'root': <String, Object?>{
            'id': 'root',
            'type': 'Column',
            'props': <String, Object?>{'gap': 18, 'align': 'stretch'},
            'children': <Object?>[
              <String, Object?>{
                'id': 'status-row',
                'type': 'Row',
                'props': <String, Object?>{'gap': 10},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'status-icon',
                    'type': 'Icon',
                    'props': <String, Object?>{
                      'name': 'check',
                      'tone': 'success',
                    },
                  },
                  <String, Object?>{
                    'id': 'status-title',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Pagamento confirmado',
                      'variant': 'title',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'receipt-card',
                'type': 'Card',
                'props': <String, Object?>{'padding': 22},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'amount-label',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Valor pago',
                      'variant': 'caption',
                      'tone': 'muted',
                    },
                  },
                  <String, Object?>{
                    'id': 'amount',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'R\$ 250,00',
                      'variant': 'display',
                    },
                  },
                  <String, Object?>{'id': 'rule', 'type': 'Divider'},
                  <String, Object?>{
                    'id': 'recipient-label',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Favorecido',
                      'variant': 'caption',
                      'tone': 'muted',
                    },
                  },
                  <String, Object?>{
                    'id': 'recipient',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Marina Souza',
                      'variant': 'body',
                    },
                  },
                  <String, Object?>{
                    'id': 'date',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': '01 de setembro de 2026 · 18:42',
                      'variant': 'caption',
                      'tone': 'muted',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'share',
                'type': 'Button',
                'props': <String, Object?>{
                  'label': 'Compartilhar comprovante',
                  'action': 'share_receipt',
                  'style': 'primary',
                  'icon': 'share',
                  'payload': <String, Object?>{'receiptId': 'RCPT-2048'},
                },
              },
            ],
          },
        },
      };

  Map<String, Object?> _personRegistrationDocument() => <String, Object?>{
        'specVersion': '1.1',
        'interaction': <String, Object?>{
          'initialState': <String, Object?>{
            'person.name': '',
            'person.cpf': '',
            'person.gender': '',
            'person.birthDate': '',
            'person.employee': false,
            'person.salary': '',
            'person.role': '',
            'person.cnpj': '',
          },
          'actions': <Object?>[
            _setValueAction('gender_female', 'person.gender', 'female'),
            _setValueAction('gender_male', 'person.gender', 'male'),
            _setValueAction('gender_other', 'person.gender', 'other'),
            _setValueAction('employee_yes', 'person.employee', true),
            _setValueAction('employee_no', 'person.employee', false),
            <String, Object?>{
              'name': 'save_person',
              'effects': <Object?>[
                <String, Object?>{'type': 'validate'},
                <String, Object?>{
                  'type': 'showMessage',
                  'tone': 'success',
                  'message': 'Cadastro validado com sucesso.',
                },
              ],
            },
            <String, Object?>{
              'name': 'cancel_person',
              'effects': <Object?>[
                <String, Object?>{'type': 'reset'},
                <String, Object?>{
                  'type': 'showMessage',
                  'tone': 'info',
                  'message': 'Formulário limpo.',
                },
              ],
            },
          ],
        },
        'screen': <String, Object?>{
          'id': 'person-registration',
          'title': 'Cadastro de pessoas',
          'root': <String, Object?>{
            'id': 'root',
            'type': 'Column',
            'props': <String, Object?>{'gap': 18, 'align': 'stretch'},
            'children': <Object?>[
              <String, Object?>{
                'id': 'title',
                'type': 'Text',
                'props': <String, Object?>{
                  'text': 'Cadastro de pessoa',
                  'variant': 'title',
                },
              },
              <String, Object?>{
                'id': 'validation-notice',
                'type': 'Notice',
                'props': <String, Object?>{
                  'title': 'Validações obrigatórias',
                  'message':
                      'Informe um CPF válido e uma data de nascimento de pessoa com 18 anos ou mais.',
                  'tone': 'info',
                },
              },
              _interactiveField(
                id: 'name',
                label: 'Nome completo',
                key: 'person.name',
                required: true,
              ),
              _interactiveField(
                id: 'cpf',
                label: 'CPF',
                key: 'person.cpf',
                required: true,
                helper: '000.000.000-00',
                validations: <Object?>[
                  <String, Object?>{'type': 'cpf'},
                ],
              ),
              _interactiveField(
                id: 'birth-date',
                label: 'Data de nascimento',
                key: 'person.birthDate',
                required: true,
                helper: 'DD/MM/AAAA',
                validations: <Object?>[
                  <String, Object?>{'type': 'minAge', 'value': 18},
                ],
              ),
              <String, Object?>{
                'id': 'gender-label',
                'type': 'Text',
                'props': <String, Object?>{
                  'text': 'Sexo',
                  'variant': 'label',
                },
              },
              <String, Object?>{
                'id': 'gender-options',
                'type': 'Row',
                'props': <String, Object?>{'gap': 8},
                'children': <Object?>[
                  _selectionButton(
                    id: 'gender-female',
                    label: 'Feminino',
                    action: 'gender_female',
                    key: 'person.gender',
                    value: 'female',
                  ),
                  _selectionButton(
                    id: 'gender-male',
                    label: 'Masculino',
                    action: 'gender_male',
                    key: 'person.gender',
                    value: 'male',
                  ),
                  _selectionButton(
                    id: 'gender-other',
                    label: 'Outro',
                    action: 'gender_other',
                    key: 'person.gender',
                    value: 'other',
                  ),
                ],
              },
              <String, Object?>{
                'id': 'employee-card',
                'type': 'Card',
                'props': <String, Object?>{'tone': 'emphasis'},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'employee-title',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text': 'Funcionário da empresa',
                      'variant': 'title',
                    },
                  },
                  <String, Object?>{
                    'id': 'employee-options',
                    'type': 'Row',
                    'children': <Object?>[
                      _selectionButton(
                        id: 'employee-yes',
                        label: 'Sim',
                        action: 'employee_yes',
                        key: 'person.employee',
                        value: true,
                      ),
                      _selectionButton(
                        id: 'employee-no',
                        label: 'Não',
                        action: 'employee_no',
                        key: 'person.employee',
                        value: false,
                      ),
                    ],
                  },
                  <String, Object?>{
                    'id': 'employee-fields',
                    'type': 'Column',
                    'props': <String, Object?>{'gap': 12},
                    'interaction': <String, Object?>{
                      'visibleWhen': <String, Object?>{
                        'key': 'person.employee',
                        'equals': true,
                      },
                    },
                    'children': <Object?>[
                      _interactiveField(
                        id: 'salary',
                        label: 'Salário',
                        key: 'person.salary',
                        required: true,
                        keyboard: 'number',
                      ),
                      _interactiveField(
                        id: 'role',
                        label: 'Cargo',
                        key: 'person.role',
                        required: true,
                      ),
                      _interactiveField(
                        id: 'cnpj',
                        label: 'CNPJ',
                        key: 'person.cnpj',
                        required: true,
                        helper: '00.000.000/0000-00',
                        validations: <Object?>[
                          <String, Object?>{'type': 'cnpj'},
                        ],
                      ),
                    ],
                  },
                ],
              },
              <String, Object?>{
                'id': 'form-actions',
                'type': 'Row',
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'save-person',
                    'type': 'Button',
                    'props': <String, Object?>{
                      'label': 'Salvar cadastro',
                      'action': 'save_person',
                      'style': 'primary',
                      'icon': 'check',
                    },
                  },
                  <String, Object?>{
                    'id': 'cancel-person',
                    'type': 'Button',
                    'props': <String, Object?>{
                      'label': 'Cancelar',
                      'action': 'cancel_person',
                      'style': 'quiet',
                      'icon': 'close',
                    },
                  },
                ],
              },
            ],
          },
        },
      };

  Map<String, Object?> _setValueAction(
    String name,
    String key,
    Object value,
  ) =>
      <String, Object?>{
        'name': name,
        'effects': <Object?>[
          <String, Object?>{
            'type': 'setValue',
            'key': key,
            'value': value,
          },
        ],
      };

  Map<String, Object?> _interactiveField({
    required String id,
    required String label,
    required String key,
    bool required = false,
    String? helper,
    String? keyboard,
    List<Object?> validations = const <Object?>[],
  }) =>
      <String, Object?>{
        'id': id,
        'type': 'TextField',
        'props': <String, Object?>{
          'label': label,
          if (helper != null) 'helper': helper,
          if (keyboard != null) 'keyboard': keyboard,
        },
        'interaction': <String, Object?>{
          'valueKey': key,
          if (required) 'required': true,
          if (validations.isNotEmpty) 'validations': validations,
        },
      };

  Map<String, Object?> _selectionButton({
    required String id,
    required String label,
    required String action,
    required String key,
    required Object value,
  }) =>
      <String, Object?>{
        'id': id,
        'type': 'Button',
        'props': <String, Object?>{
          'label': label,
          'action': action,
          'style': 'secondary',
        },
        'interaction': <String, Object?>{
          'selectedWhen': <String, Object?>{'key': key, 'equals': value},
        },
      };

  Map<String, Object?> _discoveryDocument(String brief) => <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{
          'id': 'product-hypothesis',
          'title': 'Hipótese de produto',
          'root': <String, Object?>{
            'id': 'root',
            'type': 'Column',
            'props': <String, Object?>{'gap': 18, 'align': 'stretch'},
            'children': <Object?>[
              <String, Object?>{
                'id': 'eyebrow',
                'type': 'Text',
                'props': <String, Object?>{
                  'text': 'RASCUNHO DE DESCOBERTA',
                  'variant': 'label',
                  'tone': 'muted',
                },
              },
              <String, Object?>{
                'id': 'title',
                'type': 'Text',
                'props': <String, Object?>{
                  'text': brief,
                  'variant': 'title',
                },
              },
              <String, Object?>{
                'id': 'question-card',
                'type': 'Card',
                'props': <String, Object?>{'tone': 'emphasis'},
                'children': <Object?>[
                  <String, Object?>{
                    'id': 'question',
                    'type': 'Text',
                    'props': <String, Object?>{
                      'text':
                          'Qual evidência indicaria que essa experiência merece avançar para produção?',
                      'variant': 'body',
                    },
                  },
                ],
              },
              <String, Object?>{
                'id': 'continue',
                'type': 'Button',
                'props': <String, Object?>{
                  'label': 'Registrar hipótese',
                  'action': 'register_hypothesis',
                  'style': 'primary',
                  'icon': 'arrow',
                },
              },
            ],
          },
        },
      };
}
