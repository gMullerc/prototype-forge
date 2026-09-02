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
          : _discoveryDocument(brief.text),
    );
  }

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
