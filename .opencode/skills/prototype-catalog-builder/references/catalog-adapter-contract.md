# Contrato de adaptadores de catálogo

Este documento descreve a convenção atual do Prototype Foundry. Leia-o antes de
criar ou alterar uma entrada de catálogo.

## Fronteiras

O fluxo deve permanecer:

```text
Prototype Spec -> PrototypeValidator -> PrototypeEngine
                                  -> FlutterPrototypeCatalog -> widget factory
```

O adaptador de design system fica na borda. Ele pode depender de:

- `prototype_runtime` para `ComponentContract`, `PropertyContract`,
  `PrototypeCatalog` e `PrototypePropertyType`;
- `prototype_flutter` para `FlutterPrototypeCatalog`,
  `FlutterComponentFactory`, `PrototypeRenderContext` e eventos;
- o pacote Flutter do design system que está sendo adaptado.

`prototype_spec`, `prototype_runtime` e `prototype_flutter` não podem depender
do adaptador nem do pacote de widgets.

## Mapeamento de propriedades

| API Dart pública | Contrato |
| --- | --- |
| `String` | `PrototypePropertyType.string` |
| `num`, `int`, `double` | `PrototypePropertyType.number` |
| `bool` | `PrototypePropertyType.boolean` |
| `Map` de configuração estruturada | `PrototypePropertyType.object` |
| `List` de itens declarativos | `PrototypePropertyType.list` |
| enum finito | tipo correspondente + `allowedValues` |

Parâmetro Dart `required` normalmente vira propriedade obrigatória, salvo quando
o adaptador fornece uma política segura. Parâmetros com valor padrão são
opcionais. Parâmetros internos, callbacks e objetos de plataforma não devem ser
expostos.

## Tipo semântico e ids

O `type` é uma linguagem pública do Prototype Foundry. Ele deve descrever a
intenção do componente e permanecer estável mesmo se a implementação do design
system mudar. O id de cada node continua sendo fornecido pelo documento e deve
ser único; a factory não pode gerar ids nem reescrever a árvore.

Exemplos adequados:

- `button` com `label`, `variant` e `action`;
- `text_field` com `label`, `hint`, `value` e `action`;
- `status_card` com `title`, `body` e `tone`.

Evite expor:

- `Widget`, `BuildContext`, `TextStyle`, `Color`, `EdgeInsets` ou `Function`;
- `onPressed` como código ou callback serializado;
- `child` arbitrário que não passe pelo catálogo;
- nomes de classes internas ou propriedades privadas do pacote.

## Builder Flutter

O builder recebe um `PrototypeNode` já validado e um
`PrototypeRenderContext`. Ele deve converter propriedades primitivas e tokens em
valores do design system. Quando o contrato permitir filhos, use
`context.buildChildren()` para renderizar somente nodes registrados.

Ações são dados inertes. O builder deve chamar
`context.dispatchAction(...)` com o id semântico e os dados permitidos pelo
contrato; nunca executar uma função ou interpretar uma string como código.

## Checklist de conformance

- [ ] tipo semântico estável e sem colisão;
- [ ] todas as propriedades públicas estão tipadas e limitadas;
- [ ] enums e tokens têm valores permitidos;
- [ ] propriedades desconhecidas são rejeitadas;
- [ ] componente é renderizado somente pela factory registrada;
- [ ] estados relevantes possuem teste;
- [ ] ações são eventos de dados e não callbacks executáveis;
- [ ] o adapter pode ser removido sem mudar o núcleo;
- [ ] `dart analyze`, testes do package e build Web passam.
