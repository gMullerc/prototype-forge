# Operação local

## Pré-requisitos

- Flutter 3.24.x e Dart 3.5.x;
- Chrome para executar o Studio Web;
- OpenCode instalado apenas quando a integração com o agente externo for
  necessária;
- uma sessão do OpenCode autorizada na própria máquina.

O Prototype Forge não recebe nem armazena API keys. A autenticação é uma
responsabilidade da instalação local do OpenCode.

## Windows

Na raiz do repositório:

```powershell
cd C:\dev\projects\prototype-forge
.\run-local.ps1
```

Se o Flutter não estiver no `PATH`, informe o executável:

```powershell
.\run-local.ps1 -FlutterPath C:\caminho\para\flutter.bat
```

O script inicia o gateway local e o Studio no Chrome. Ao encerrar com `Ctrl+C`,
ele encerra apenas o gateway iniciado por aquela execução.

## macOS e Linux

Na raiz do repositório:

```bash
cd /caminho/para/prototype-forge
bash ./run-local.sh
```

Se o Flutter não estiver no `PATH`, passe o executável como primeiro argumento:

```bash
bash ./run-local.sh /Users/voce/development/flutter/bin/flutter
```

## Portas e processos

| Serviço | Padrão | Função |
| --- | ---: | --- |
| Gateway | `127.0.0.1:8790` | API local consumida pelo Studio |
| OpenCode | `127.0.0.1:4096` | servidor OpenCode, iniciado sob demanda |
| Studio | porta definida pelo Flutter | aplicação Flutter Web no Chrome |

O gateway é a única fronteira do Studio com o OpenCode. A aplicação Flutter
não chama a API do provedor diretamente.

## Configuração opcional

As variáveis abaixo alteram a execução sem editar o código:

| Variável | Uso |
| --- | --- |
| `PROTOTYPE_GATEWAY_PORT` | porta do gateway local |
| `PROTOTYPE_OPENCODE_PORT` | porta do servidor OpenCode |
| `PROTOTYPE_OPENCODE_EXECUTABLE` | executável alternativo do OpenCode |
| `PROTOTYPE_OPENCODE_MODEL` | modelo no formato `provider/model` |
| `PROTOTYPE_OPENCODE_VARIANT` | variante de raciocínio do modelo |
| `PROTOTYPE_COPILOT_EXECUTABLE` | executável alternativo do Copilot CLI |
| `PROTOTYPE_COPILOT_MODEL` | modelo opcional do Copilot CLI |
| `PROTOTYPE_COPILOT_TIMEOUT_SECONDS` | limite da geração do Copilot CLI |
| `PROTOTYPE_WORKSPACE` | diretório de trabalho isolado do OpenCode |

Exemplo no PowerShell:

```powershell
$env:PROTOTYPE_OPENCODE_MODEL = 'openai/gpt-5.4'
.\run-local.ps1
```

Por padrão, o workspace do OpenCode é a raiz do monorepo. Isso permite que a
skill local de catálogo em `.opencode/skills` seja descoberta quando ela for
usada em um fluxo explícito de manutenção.

## Modos de agente

- `deterministic`: fixture local para desenvolvimento, testes e demonstração
  sem depender de processo externo;
- `opencode`: integração via gateway, usando a sessão autorizada do OpenCode.
- `copilot`: integração via gateway, usando o modo programático do Copilot CLI.

O Studio depende apenas da porta `PrototypeAgent`. Adicionar outro provedor
deve ser uma implementação de infraestrutura e uma alteração na composition
root, sem alterar o runtime ou o renderer.

## Ferramentas locais detectadas

O botão de ferramentas no cabeçalho consulta `GET /v1/tools` no gateway local.
Essa consulta verifica apenas comandos registrados no `PATH` e suas versões.
Uma ferramenta marcada como “detectada” ainda pode exigir login próprio antes
de ser usada; o Prototype Foundry não lê nem armazena credenciais.

## Validação do repositório

Para executar análise, testes e build Web:

```powershell
.\check.ps1
```

O gate verifica os packages Dart, o gateway e o Studio Flutter.

## Diagnóstico rápido

### “OpenCode indisponível”

1. confirme que o OpenCode está instalado e disponível no `PATH`;
2. confirme que a sessão do OpenCode está autorizada;
3. verifique se a porta `4096` não está ocupada por outro processo;
4. tente primeiro o agente `deterministic` para separar problema do Studio de
   problema do provedor.

### “Contrato rejeitado”

A rejeição é deliberada: o runtime bloqueia componentes, propriedades,
profundidade ou ids fora do contrato. Leia o diagnóstico do Studio para
identificar o componente afetado, a regra e a sugestão de correção. Nenhum
contrato rejeitado chega ao renderer.

### Mensagens do Chrome sobre lifecycle ou `FoundryApp`

Mensagens de lifecycle podem aparecer durante a inicialização do Flutter Web e
não são, por si só, evidência de falha do contrato. Se o Studio não carregar,
encerre a execução, rode novamente o script e valide o ambiente com
`.\check.ps1`.

## Limites operacionais do MVP

O processo é local. Não há garantia de backup, sincronização, isolamento entre
usuários ou recuperação depois que os dados do navegador forem apagados.
Projetos, revisões e comentários são mantidos no `localStorage` do
mesmo perfil do Chrome usado para abrir o Studio. Não há sincronização, backup
ou nuvem. Esses temas pertencem ao futuro produto hospedado e devem ser
decididos antes de qualquer implementação de autenticação ou Electron.
