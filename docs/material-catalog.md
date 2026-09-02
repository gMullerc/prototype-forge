# Material fixture catalog

The Material catalog is a public, local development fixture. Its purpose is to
make the Studio useful before the company design system is integrated and to
exercise scenarios close to real product work.

It is an adapter, not a dependency of the contract or runtime. The prototype
document only contains semantic types and approved properties; Flutter Material
details stay inside this package.

## Current components

| Type | Purpose | Main properties |
| --- | --- | --- |
| `Column` | Vertical composition | `gap`, `align` |
| `Row` | Responsive horizontal composition | `gap` |
| `List` | Spaced collection | `gap` |
| `Text` | Copy and hierarchy | `text`, `variant`, `tone`, `align` |
| `Icon` | Approved iconography | `name`, `tone` |
| `Divider` | Visual separation | — |
| `Card` | Grouped surface | `tone`, `padding` |
| `Button` | Explicit user action | `label`, `action`, `style`, `icon`, `payload` |
| `Avatar` | Identity or account marker | `name`, `initials`, `tone`, `size` |
| `Badge` | Status or category label | `label`, `tone` |
| `TextField` | Form input preview | `label`, `placeholder`, `value`, `helper`, `keyboard` |
| `Notice` | Contextual feedback or guidance | `title`, `message`, `tone`, `icon` |
| `Metric` | Highlighted value and context | `label`, `value`, `trend`, `tone` |
| `ListItem` | Transaction or navigation row | `label`, `supporting`, `trailing`, `icon`, `action` |

All values remain contract data. `TextField` is intentionally read-only in the
MVP: it communicates the intended form layout without pretending to implement
production form state or submission.

## Local scenarios

The deterministic local agent selects fixtures from the PM brief:

- `pagamento` or `comprovante`: payment receipt with amount, recipient, date and
  share action;
- `login`, `acesso` or `senha`: account access screen with security notice,
  email/password fields and recovery actions;
- `banco`, `saldo` or `conta`: banking home with account header, balance,
  credit-card metrics and recent transactions;
- any other brief: discovery screen used to explore a new hypothesis.

The selection is isolated in `LocalPrototypeScenarioRegistry`. A new local
fixture can be injected into `LocalPrototypeAgent` with keywords and a document
builder, without changing the dispatch logic or any Foundry package:

```dart
final agent = LocalPrototypeAgent(
  scenarioRegistry: LocalPrototypeScenarioRegistry(
    scenarios: <LocalPrototypeScenario>[
      LocalPrototypeScenario(
        id: 'checkout',
        keywords: const <String>['checkout', 'carrinho'],
        builder: buildCheckoutDocument,
      ),
    ],
    fallback: buildDiscoveryDocument,
  ),
);
```

The registry is a Studio fixture seam only. OpenCode receives the active
catalog contracts and can compose any valid tree from the registered
components.

## Adding a temporary component

The Material factory is extensible at the composition root:

```dart
final catalog = createMaterialPrototypeCatalog(
  additionalFactories: <FlutterComponentFactory>[
    FlutterComponentFactory(
      contract: ComponentContract(type: 'CompanyHeader'),
      builder: buildCompanyHeader,
    ),
  ],
);
```

A lasting component should live in its own catalog adapter package and include
its contract, factory, model guidance, widget tests and exporter strategy. The
core packages must not be changed to teach them about Material or the company
design system.
