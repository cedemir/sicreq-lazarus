# SICREQ3 — Controle de acervo de quadrinhos (Lazarus + Zeos + Fortes Report)

Sistema desktop em Free Pascal / Lazarus 4.8 sobre o banco MySQL modelado a partir de `sicreq2.sql`.

## Componentes usados

| Componente | Pacote Lazarus | Uso |
|---|---|---|
| ZeosLib 8.0 (`TZConnection`, `TZQuery`, `TZReadOnlyQuery`) | `zcomponent` | Acesso ao MySQL |
| Fortes Report CE (`TRLReport`, `TRLBand`, `TRLGroup`, `TRLDBText`, `TRLSystemInfo`, `TRLPDFFilter`) | `frce` | Relatórios, prévia, impressão e PDF |
| LCL padrão (`TDBGrid`, `TDBEdit`, `TDBMemo`, `TDBLookupComboBox`, `TDBDateEdit`, `TOpenPictureDialog`, `TSpinEdit`) | `LCL` | Telas |

Nenhum componente de terceiros além de Zeos e Fortes.

## 1. Banco de dados

```bash
# cria o banco sicreq3 com todas as tabelas e chaves estrangeiras
mysql -u root -p < sql/sicreq3_schema.sql

# (opcional) copia os dados do banco sicreq2 já existente no servidor
mysql -u root -p sicreq3 < sql/migrar_de_sicreq2.sql
```

As tabelas `cache` e `sessions` do dump eram do Laravel e não foram incluídas.
Se preferir, o sistema também funciona apontando direto para o banco `sicreq2` (basta informar `sicreq2` na configuração da conexão).

## 2. Biblioteca cliente do MySQL

O Zeos carrega a biblioteca cliente em tempo de execução:

```bash
sudo apt install libmysqlclient21      # -> libmysqlclient.so.21
# ou: sudo apt install libmariadb3     # -> libmariadb.so.3
```

No Windows, coloque `libmysql.dll` (mesma arquitetura do executável) ao lado do `.exe`.

## 3. Pacotes no Lazarus

1. **Zeos**: `Pacote > Abrir arquivo de pacote` → `zeosdbo/packages/lazarus/zcomponent.lpk` → Compilar; depois abra `zcomponentdesign.lpk` → Usar → Instalar.
2. **Fortes Report CE**: clone `https://github.com/fortesinformatica/fortesreport-ce`, abra `Packages/frce.lpk` → Usar → Instalar.
3. Abra `sicreq.lpi` e compile (Shift+F9).

## 4. Configuração

Na primeira execução, se a conexão falhar, aparece a tela de configuração; ela grava `sicreq.ini` ao lado do executável (veja `sicreq.ini.exemplo`). Pode ser alterada depois em **Sistema > Configurar conexão**.

## Login e usuários

- **Primeiro acesso:** a tabela `usuario` é criada automaticamente. Se ela estiver vazia, a tela de login vira **Primeiro acesso** e cria o administrador.
- **Login:** pede usuário e senha e lembra o último login usado em `sicreq.ini` (nunca a senha). Cada tentativa errada espera um pouco mais antes de responder.
- **Senhas:** guardadas como hash **PBKDF2-HMAC-SHA1** com sal aleatório e 20 000 iterações, usando as unidades `sha1`/`hmac` do próprio FPC. A implementação foi conferida com os vetores oficiais da RFC 6070.
- **Perfis:**

  | Perfil | Pode |
  |---|---|
  | Administrador | tudo: acervo, **Usuários**, alterar a conexão |
  | Operador | incluir, alterar e excluir no acervo |
  | Consulta | apenas visualizar (botão **Ver** abre o registro só para leitura) |

- **Usuários** (menu, só administrador): nome, login, e-mail, perfil, situação (ativo/inativo) e senha. Na edição, a senha em branco mantém a atual. O sistema impede excluir o próprio usuário e ficar sem nenhum administrador ativo.
- **Configurações → Alterar minha senha:** qualquer usuário troca a própria senha (pede a senha atual).
- **Sair:** encerra a sessão e volta ao login. **Esc** no login fecha o sistema.

## Interface

Tema escuro no estilo painel web, numa janela única:

- **Menu lateral:** logotipo, cartão do banco conectado (nome, usuário, versão do MySQL), itens de menu e usuário no rodapé.
- **Cabeçalho:** status da conexão (● verde) e botão **Sair**.
- **Páginas de cadastro:** seção em azul claro, título, descrição, botões **Imprimir** e **+ Novo…**. Abaixo, um cartão com **pesquisa ao digitar**, **filtro por combo** (editora, universo, tamanho, função) e tabela com botões por linha (**Editar**, **Excluir** e os detalhes, por exemplo **Exemplares**).
- **Edição:** diálogo escuro com os campos. **F2** salva, **Esc** cancela.
- **Combos:** filtro e campos de escolha usam o `TCaixaEscolha` (`src/uescolha.pas`), escuro também com a lista fechada e com a seta, em qualquer sistema. Listas com 12 itens ou mais ganham pesquisa ao abrir. Setas, Home/End e as primeiras letras escolhem sem abrir a lista; Enter, Espaço ou F4 abrem.
- **Exclusão:** confirmação no mesmo tema.

Botões, cartões e caixas de texto são controles próprios pintados em `src/utema.pas`, porque botões nativos não aceitam cor no GTK2/Windows. Não há componentes de terceiros. As cores ficam em `initialization` de `utema.pas`.

## Formulários visuais (designer do Lazarus)

**Todas as telas de cadastro** são formulários visuais (`.lfm`) e aparecem em *Projeto > Formulários*:

| O quê | Arquivos | Tipo |
|---|---|---|
| Listagem de cada tabela | `src/telas/ulista<tabela>.pas/.lfm` | `TFrame` (`TFraLista…`) |
| Inclusão/edição de cada tabela | `src/telas/ueditar<tabela>.pas/.lfm` | `TForm` (`TFrmEditar…`) |
| Login, Conexão, Usuário, Alterar minha senha | `src/ulogin`, `uconfig`, `uusuarios`, `uminhasenha` | `TForm` |

São 16 listagens e 15 edições (a de usuário é o `uusuarios`).

**As telas não têm código.** O comportamento comum (pesquisa, filtro, botões por linha, permissões, validação, numeração automática) fica em `src/ucadastro.pas` (listagem) e `src/uedicao.pas` (edição). Essas units adotam os componentes da tela **pelo nome**. Por isso:

- **Pode** mover, redimensionar, trocar textos, cores e fontes, mudar a ordem e a largura das colunas, remover colunas e acrescentar rótulos e painéis.
- **Não renomeie** os componentes usados pelo sistema:
  - Listagem: `Grid`, `QryLista`, `DsLista`, `EdtBusca`, `CbFiltro`, `BtnNovo`, `BtnImprimir`, `BtnVoltar`, `PnlTrilha`, `LblTrilha`, `LblContagem`.
  - Edição: `QryRegistro`, `DsRegistro`, `BtnSalvar`, `BtnCancelar`, `LblTitulo`, `LblTrilha`, e por campo `Lbl_<campo>`, `Pnl_<campo>`, `Edt_<campo>`, `BtnArq_<campo>`, `BtnVer_<campo>`.
- **Campos de edição** já vêm ligados ao banco no designer (`DataSource = DsRegistro`, `DataField`). Os `TDBLookupComboBox` viram a combo escura ao abrir, e os itens vêm de `udefinicoes.pas`.
- **Colunas do `Grid`**: o `Tag` define o estilo (0 normal, 1 negrito, 2 número âmbar, 3 suave). A coluna com `Tag = 100` recebe os botões de ação. **Imprimir** usa as colunas que estiverem na grade.
- **Regras** (SQL, chave, obrigatórios, numeração automática, valores padrão, detalhes, filtro) continuam em `src/udefinicoes.pas`.

O visual escuro arredondado é aplicado ao abrir a tela por `AplicarTema` (`src/utemaform.pas`), conforme a propriedade **Tag**:

| Componente | Tag | Vira |
|---|---|---|
| `TButton` | 1 | botão azul (primário) |
| `TButton` | 2 | botão contornado (secundário) |
| `TButton` | 3 | botão vermelho (perigo) |
| `TPanel` | 10 | caixa de campo arredondada (ponha o `TEdit`/`TDBEdit` dentro, com `BorderStyle = bsNone`) |
| `TPanel` | 11 | cartão arredondado com borda |
| `TPanel` | 12 | logotipo (quadrado azul com o `Caption`) |

No designer os botões aparecem nativos e os cantos retos; com o programa rodando, ficam no tema.

### Tela para uma tabela nova

1. Descreva a tabela em `src/udefinicoes.pas` (como as demais).
2. Gere as telas a partir dessa descrição:
   ```bash
   fpc -Fusrc tools/exportar_definicoes.lpr        # ou abra no Lazarus e compile
   tools/exportar_definicoes > /tmp/definicoes.json
   python3 tools/gerar_telas.py /tmp/definicoes.json src/telas minha_tabela
   ```
   O gerador **nunca sobrescreve** telas existentes, a não ser com `--sobrescrever`.
3. No Lazarus: *Projeto > Adicionar arquivo ao projeto* com `ulistaminhatabela.pas` e `ueditarminhatabela.pas`.

Outra opção é copiar uma tela parecida (*Arquivo > Salvar como*), renomear a classe e trocar o nome da tabela em `RegistrarLista`/`RegistrarEdicao` no fim da unit.

## Como o sistema funciona

- **Títulos** é a entrada do acervo. Na linha de um título, **Exemplares** abre a página filha já filtrada. Dali, **Histórias**, e depois **Artistas** e **Personagens**. A trilha aparece no topo, junto com **‹ Voltar** (ou **Alt+Backspace**).
- **Personagens → Criadores / Imagens** e **Artistas → Personagens criados** usam `personagem_criador` pelos dois lados.
- Números de exemplar, de história e de imagem são sugeridos como o maior + 1 dentro do mestre.
- **Imprimir** gera pelo Fortes Report a listagem do que está na tabela, respeitando pesquisa e filtro.
- **Atalhos:** **Ctrl+N** cria um registro, **Ctrl+F** vai para a pesquisa, **F5** recarrega, **Enter** ou duplo clique edita, **Delete** exclui.
- **Painel:** mostra os totais do acervo e os títulos com mais exemplares.
- Campos de imagem (`artista_foto`, `exemplar_capa`, `imagem_descricao`) guardam o caminho do arquivo. Imagens dentro da pasta `imagens/` ao lado do executável são gravadas com caminho relativo (os campos têm no máximo 100 caracteres).

### Relatórios (Fortes Report, visuais)

Cada relatório é um **formulário com `TRLReport` desenhado no designer** (`src/relatorios/*.lfm`). Abra o `.lfm` e edite bandas, rótulos, campos, fontes e logotipo com a paleta do Fortes. O SQL de cada um fica em `src/urelatorios.pas`.

| Relatório | Arquivo | Estrutura |
|---|---|---|
| Ficha do título (**novo**) | `urelfichatitulo` | dados do título (`BandaTitulo`); por exemplar, faixa cinza e as histórias com artistas e personagens (grupo por exemplar) |
| Títulos por editora | `ureltituloseditora` | grupo por editora, subtotal |
| Acervo: exemplares por título | `urelacervo` | grupo por título, subtotal |
| Histórias com artistas e personagens | `urelhistorias` | grupo por edição, paisagem |
| Personagens por universo | `urelpersonagensuniverso` | grupo por universo, subtotal |
| Criadores de personagens | `urelcriadores` | grupo por artista, subtotal |
| Listagem do botão **Imprimir** | `urellistagem` | cabeçalho, resumo e rodapé desenhados; as colunas são criadas a partir do `Grid` da tela |

- **Ficha do título:** escolha o título na página **Relatórios** (só aparecem títulos com exemplares) e clique em **Gerar ficha**.
- **Pré-visualização:** permite imprimir e salvar em **PDF** (`RLPDFFilter1` em cada relatório).
- **Campo novo num relatório:** inclua a coluna no SQL em `urelatorios.pas` e ponha um `TRLDBText` com o mesmo `DataField` na banda desejada.
- **Não renomeie** `RLReport1` nem as consultas (`QryRel`; na ficha, `QryTitulo` e `QryItens`). Na listagem, mantenha também `BandaColunas`, `BandaDetalhe`, `LblTitulo`, `LblSubtitulo` e `DsRel`.

## Estrutura

```
sicreq.lpi / sicreq.lpr     projeto
src/udm.pas (+.lfm)         DataModule com TZConnection, leitura do sicreq.ini
src/udefinicoes.pas         regras de TODAS as tabelas (SQL, chaves, obrigatórios, filtros, detalhes)
src/telas/                  telas visuais: ulista<tabela> (TFrame) e ueditar<tabela> (TForm)
src/utelas.pas              registro das telas por tabela
src/utema.pas               cores e controles pintados (TBotao, TCartao), diálogos no tema
src/uescolha.pas            TCaixaEscolha: combo escuro desenhado pelo programa (com ligação a campo)
src/ucadastro.pas           comportamento das listagens (adota o frame da tabela)
src/uedicao.pas             comportamento da inclusão/edição (adota o formulário da tabela)
src/upaginas.pas            páginas Painel, Relatórios e Configurações
src/urelatorios.pas         SQL dos relatórios e chamada da pré-visualização
src/relatorios/             relatórios visuais (TRLReport desenhado em .lfm)
src/uconfig.pas (+.lfm)     diálogo de conexão                    [formulário visual]
src/ulogin.pas (+.lfm)      tela de login / primeiro acesso       [formulário visual]
src/uusuarios.pas (+.lfm)   cadastro de usuário                   [formulário visual]
src/uminhasenha.pas (+.lfm) alterar minha senha                   [formulário visual]
src/utemaform.pas           AplicarTema: dá o visual escuro aos formulários visuais
src/usessao.pas             sessão, perfis, hash de senha (PBKDF2), autenticação
src/uprincipal.pas (+.lfm)  janela principal: menu lateral, cabeçalho, pilha de páginas
sql/                        scripts do banco
tools/                      gerador de telas (exportar_definicoes.lpr + gerar_telas.py)
```

**Onde mudar o quê:**
- **Visual** (rótulos, textos, posições, colunas, larguras, cores): no designer, nas telas de `src/telas`.
- **Regras** (SQL da listagem, campos obrigatórios, numeração automática, valores padrão, filtro, detalhes): em `src/udefinicoes.pas`.
- **Campo novo numa tabela:** descreva-o em `udefinicoes.pas` e acrescente no formulário de edição um `Lbl_<campo>` e um `Edt_<campo>` (`TDBEdit` com `DataSource = DsRegistro` e `DataField = '<campo>'`), de preferência dentro de um `TPanel` com `Tag = 10`.

## Suposições a conferir

Alguns campos `SMALLINT` do dump não têm significado documentado. Interpretei assim (os textos ficam em constantes no topo de `udefinicoes.pas`):

- `exemplar.exemplar_situacao`: 0 = NÃO POSSUO, 1 = POSSUO
- `historia.historia_cor`: 0 = PRETO E BRANCO, 1 = COLORIDA
- `artista_historia.participa_artistahistoria`: 1 Roteiro, 2 Desenho, 3 Arte-final, 4 Cores, 5 Letras, 6 Capa, 7 Edição, 8 Roteiro e arte
- `titulo.titulo_periodicidade`: mantido como número livre
