# Contexto do produto

## Problema

Hoje um PM precisa transformar uma hipótese em uma tela antes de conseguir
discuti-la com o time técnico. Esse caminho é lento, produz protótipos que
podem se afastar do design system e frequentemente mistura exploração de
produto com decisões de implementação.

O Prototype Forge cria uma etapa intermediária: o PM descreve a intenção, o
agente propõe uma composição declarativa e o runtime mostra uma superfície
interativa usando apenas componentes aprovados.

## Usuário principal

O usuário do MVP é o PM que precisa:

- testar rapidamente uma hipótese de tela ou fluxo;
- discutir a proposta com design e engenharia;
- enxergar uma interface próxima do sistema visual adotado;
- repetir o briefing sem editar código;
- levar para o time um artefato técnico legível e validado.

O MVP não transforma o PM em mantenedor do catálogo nem concede acesso de
execução ao repositório do produto.

## Visão

Evoluir de uma ferramenta que apenas exibe telas para uma bancada de
exploração de produto baseada em contratos:

```text
interface estática
  -> interface declarativa
  -> interface composta por agente
  -> rascunho técnico revisável
```

A visão não é permitir que o modelo invente qualquer widget. A vantagem vem
de combinar flexibilidade na composição com controle sobre os componentes,
tokens, estados e ações que podem aparecer.

## Jornada do MVP

1. O PM abre o Studio localmente.
2. Escolhe o agente disponível — inicialmente o OpenCode ou o agente
   determinístico de demonstração.
3. Escreve uma hipótese, por exemplo: “crie uma tela inicial de banco com
   saldo, cartão de crédito e fatura”.
4. O agente devolve um Prototype Spec JSON.
5. O Foundry valida o contrato contra o catálogo ativo.
6. Se aprovado, o Studio renderiza o protótipo.
7. Se rejeitado, o Studio apresenta causa, componente, propriedade, caminho
   técnico e próxima ação sugerida.

## O que fica dentro do MVP

- uma aplicação Flutter Web executada localmente;
- um contrato JSON próprio, pequeno e versionado;
- validação estrita antes da renderização;
- catálogo Material público para testes;
- fronteira de catálogo que permita trocar o Material pelo design system da
  empresa;
- agente determinístico para desenvolvimento sem credenciais;
- integração OpenCode por um gateway local;
- histórico de conversa enquanto a sessão estiver aberta;
- feedback de rejeição de contrato que o PM consiga entender.

## O que fica fora do MVP

- autenticação ou gerenciamento de usuários;
- servidor remoto, banco de dados ou persistência em nuvem;
- Electron;
- commits, branches ou escrita automática nos repositórios de produto;
- execução de Dart, JavaScript, HTML arbitrário ou scripts gerados;
- compatibilidade total com A2UI ou dependência do GenUI;
- suporte a qualquer design system sem um adapter explícito;
- navegação complexa, estado de produção e integração com APIs de negócio.

## Princípios

### Flexibilidade por composição

O Studio escolhe implementações na composition root. O core não conhece
OpenCode, o design system da empresa ou detalhes de Flutter além da camada
Flutter adapter.

### Contrato como fronteira

O JSON versionado é o ponto de integração entre agentes, runtime, catálogos e
renderer. Isso permite trocar o agente ou o design system sem reescrever a
regra de negócio do Foundry.

### Segurança por redução de capacidade

O preview só conhece factories registradas, propriedades validadas e ações
inertes. Quanto menos capacidade o contrato concede, menor a superfície para
um output incorreto ou malicioso.

### Feedback orientado à ação

Uma rejeição é parte do produto. O PM deve saber o que falhou, onde falhou,
qual o impacto e o que pode pedir ao agente ou ajustar no briefing.

### Caminho claro para produção

O protótipo deve ser legível para engenharia e permanecer próximo do catálogo
real. O objetivo futuro é exportar um rascunho determinístico, sempre sujeito
à revisão humana, sem transformar o MVP em um gerador de código opaco.

## Critérios para trocar o catálogo

Um catálogo novo é aceitável quando:

- implementa a mesma interface de adapter;
- declara os mesmos tipos semânticos ou uma cobertura explicitamente
  documentada;
- valida propriedades e tokens;
- fornece factories Flutter e testes;
- passa a suíte de conformidade compartilhada;
- não exige mudanças em `prototype_spec`, `prototype_runtime`,
  `prototype_flutter`, agentes ou gateway.

O catálogo Material permanece como fixture para desenvolvimento e teste mesmo
depois da integração com o design system da empresa.
