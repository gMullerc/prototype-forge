import 'dart:convert';

import 'package:prototype_agent/prototype_agent.dart';

class LocalPrototypeAgent implements PrototypeAgent {
  const LocalPrototypeAgent();

  @override
  String get id => 'local-contract';

  @override
  String get label => 'Motor local';

  @override
  Future<String> generate(PrototypeBrief brief) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final String normalized = brief.text.toLowerCase();
    return jsonEncode(
      normalized.contains('pagamento') || normalized.contains('comprovante')
          ? _receiptDocument()
          : normalized.contains('login') ||
                  normalized.contains('acesso') ||
                  normalized.contains('senha')
              ? _loginDocument()
              : normalized.contains('banco') ||
                      normalized.contains('saldo') ||
                      normalized.contains('conta')
                  ? _bankHomeDocument()
                  : _discoveryDocument(brief.text),
    );
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
