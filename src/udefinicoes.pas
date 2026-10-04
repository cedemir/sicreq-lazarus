unit uDefinicoes;

{ Metadados das tabelas do SICREQ.
  Cada tabela é descrita uma única vez aqui (campos de edição, colunas do
  grid/relatório, consultas de lookup e tabelas de detalhe). O formulário
  genérico de cadastro (uCadastro) monta a tela a partir dessa descrição. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants;

type
  TTipoCampo = (tcTexto, tcMemo, tcInteiro, tcDecimal, tcData, tcLookup, tcImagem);

  TOpcaoCampo = (ocObrigatorio, ocSomenteLeitura, ocAutoNumero);
  TOpcoesCampo = set of TOpcaoCampo;

  TCampoDef = record
    Nome: string;
    Rotulo: string;
    Tipo: TTipoCampo;
    Largura: Integer;
    Opcoes: TOpcoesCampo;
    { Para tcLookup: SELECT que devolve as colunas "codigo" e "descricao" }
    LookupSQL: string;
    { Valor sugerido ao incluir um registro (Null = nenhum) }
    Padrao: Variant;
  end;

  { ecDestaque = negrito (nome do registro); ecNumero = âmbar em negrito }
  TEstiloColuna = (ecNormal, ecDestaque, ecNumero, ecSuave);

  TColunaDef = record
    Campo: string;
    Titulo: string;
    Largura: Integer;
    Estilo: TEstiloColuna;
  end;
  TColunasDef = array of TColunaDef;

  TLigacao = record
    CampoDetalhe: string;
    CampoMestre: string;
  end;

  TFiltroFixo = record
    Campo: string;
    Valor: Variant;
  end;
  TFiltrosFixos = array of TFiltroFixo;

  TTabelaDef = class;

  { Editor próprio (substitui o diálogo genérico) - ex.: usuários, por causa da senha }
  TEditorRegistro = function(ADef: TTabelaDef; const AChave: Variant;
    const AFixos: TFiltrosFixos; const ATrilha: string;
    out AChaveGravada: Variant): Boolean;
  { Devolve a mensagem que impede a exclusão, ou '' se pode excluir }
  TValidarExclusao = function(const AChave: Variant): string;

  TDetalheDef = record
    Rotulo: string;
    Tabela: string;
    Ligacoes: array of TLigacao;
  end;

  { TTabelaDef }

  TTabelaDef = class
  public
    Tabela: string;          // nome físico
    Titulo: string;          // título da janela / relatório
    Chave: string;           // chave primária (auto-incremento)
    Alias: string;           // alias usado em SQLGrid
    SQLGrid: string;         // SELECT ... FROM ... (sem WHERE / ORDER BY)
    CampoBusca: string;      // expressão usada no filtro LIKE
    Ordem: string;           // ORDER BY
    RotuloRegistro: string;  // ex.: 'Título', usado na trilha de navegação
    CampoDescricao: string;  // campo que identifica o registro para o usuário
    { Apresentação da página }
    Secao: string;           // texto pequeno acima do título (ex.: 'ACERVO')
    Descricao: string;       // frase abaixo do título
    TextoNovo: string;       // ex.: 'Novo título'
    NomeSingular: string;    // ex.: 'título' -> 'Editar título'
    { Filtro opcional por combo (ao lado da busca) }
    FiltroCampo: string;     // expressão SQL, ex.: 't.editora_codigo'
    FiltroTodos: string;     // ex.: 'Todas as editoras'
    FiltroSQL: string;       // SELECT codigo, descricao
    Editor: TEditorRegistro;
    ValidarExclusao: TValidarExclusao;
    Campos: array of TCampoDef;
    Colunas: TColunasDef;
    Detalhes: array of TDetalheDef;
    function Campo(const ANome, ARotulo: string; ATipo: TTipoCampo;
      ALargura: Integer; AOpcoes: TOpcoesCampo = [];
      const ALookupSQL: string = ''): TTabelaDef;
    { Define o valor padrão do último campo adicionado }
    function Padrao(const AValor: Variant): TTabelaDef;
    function Coluna(const ACampo, ATitulo: string; ALargura: Integer;
      AEstilo: TEstiloColuna = ecNormal): TTabelaDef;
    function Apresentar(const ASecao, ADescricao, ATextoNovo,
      ANomeSingular: string): TTabelaDef;
    function Filtro(const ACampo, ATodos, ASQL: string): TTabelaDef;
    { ALigacoes: pares (campo do detalhe, campo do mestre) }
    function Detalhe(const ARotulo, ATabela: string;
      const ALigacoes: array of string): TTabelaDef;
  end;

const
  SQL_EDITORA     = 'SELECT editora_codigo AS codigo, editora_descricao AS descricao FROM editora ORDER BY editora_descricao';
  SQL_TIPO_TITULO = 'SELECT tipotitulo_codigo AS codigo, tipotitulo_descricao AS descricao FROM tipo_titulo ORDER BY tipotitulo_descricao';
  SQL_SITUACAO    = 'SELECT situacao_codigo AS codigo, situacao_descricao AS descricao FROM situacao_titulo ORDER BY situacao_descricao';
  SQL_UNIVERSO    = 'SELECT universo_codigo AS codigo, universo_descricao AS descricao FROM universo ORDER BY universo_descricao';
  SQL_ARMAZENAGEM = 'SELECT armazenagem_codigo AS codigo, armazenagem_descricao AS descricao FROM armazenagem ORDER BY armazenagem_descricao';
  SQL_TAMANHO     = 'SELECT tamanho_codigo AS codigo, tamanho_descricao AS descricao FROM tamanho ORDER BY tamanho_descricao';
  SQL_ARTISTA     = 'SELECT artista_codigo AS codigo, artista_nome AS descricao FROM artista ORDER BY artista_nome';
  SQL_PERSONAGEM  = 'SELECT personagem_codigo AS codigo, personagem_descricao AS descricao FROM personagem ORDER BY personagem_descricao';

  { Listas fixas para colunas SMALLINT codificadas. Ajuste os textos se o
    significado dos códigos no seu acervo for outro. }
  SQL_SITUACAO_EXEMPLAR =
    'SELECT 0 AS codigo, ''NÃO POSSUO'' AS descricao UNION ALL ' +
    'SELECT 1, ''POSSUO''';
  SQL_COR_HISTORIA =
    'SELECT 0 AS codigo, ''PRETO E BRANCO'' AS descricao UNION ALL ' +
    'SELECT 1, ''COLORIDA''';
  SQL_PARTICIPACAO =
    'SELECT 1 AS codigo, ''ROTEIRO'' AS descricao UNION ALL ' +
    'SELECT 2, ''DESENHO'' UNION ALL SELECT 3, ''ARTE-FINAL'' UNION ALL ' +
    'SELECT 4, ''CORES'' UNION ALL SELECT 5, ''LETRAS'' UNION ALL ' +
    'SELECT 6, ''CAPA'' UNION ALL SELECT 7, ''EDIÇÃO'' UNION ALL ' +
    'SELECT 8, ''ROTEIRO E ARTE''';

  { Mesmos textos, para uso em CASE dentro dos SELECT do grid }
  CASE_SITUACAO_EXEMPLAR =
    'CASE x.exemplar_situacao WHEN 1 THEN ''POSSUO'' WHEN 0 THEN ''NÃO POSSUO'' END';
  CASE_COR_HISTORIA =
    'CASE h.historia_cor WHEN 1 THEN ''COLORIDA'' ELSE ''PRETO E BRANCO'' END';
  CASE_PARTICIPACAO =
    'CASE ah.participa_artistahistoria WHEN 1 THEN ''ROTEIRO'' WHEN 2 THEN ''DESENHO'' ' +
    'WHEN 3 THEN ''ARTE-FINAL'' WHEN 4 THEN ''CORES'' WHEN 5 THEN ''LETRAS'' ' +
    'WHEN 6 THEN ''CAPA'' WHEN 7 THEN ''EDIÇÃO'' WHEN 8 THEN ''ROTEIRO E ARTE'' END';

function Definicao(const ATabela: string): TTabelaDef;

implementation

var
  FDefinicoes: TStringList;

{ TTabelaDef }

function TTabelaDef.Campo(const ANome, ARotulo: string; ATipo: TTipoCampo;
  ALargura: Integer; AOpcoes: TOpcoesCampo; const ALookupSQL: string): TTabelaDef;
var
  N: Integer;
begin
  N := Length(Campos);
  SetLength(Campos, N + 1);
  Campos[N].Nome := ANome;
  Campos[N].Rotulo := ARotulo;
  Campos[N].Tipo := ATipo;
  Campos[N].Largura := ALargura;
  Campos[N].Opcoes := AOpcoes;
  Campos[N].LookupSQL := ALookupSQL;
  Campos[N].Padrao := Null;
  Result := Self;
end;

function TTabelaDef.Padrao(const AValor: Variant): TTabelaDef;
begin
  Campos[High(Campos)].Padrao := AValor;
  Result := Self;
end;

function TTabelaDef.Coluna(const ACampo, ATitulo: string; ALargura: Integer;
  AEstilo: TEstiloColuna): TTabelaDef;
var
  N: Integer;
begin
  N := Length(Colunas);
  SetLength(Colunas, N + 1);
  Colunas[N].Campo := ACampo;
  Colunas[N].Titulo := ATitulo;
  Colunas[N].Largura := ALargura;
  Colunas[N].Estilo := AEstilo;
  Result := Self;
end;

function TTabelaDef.Apresentar(const ASecao, ADescricao, ATextoNovo,
  ANomeSingular: string): TTabelaDef;
begin
  Secao := ASecao;
  Descricao := ADescricao;
  TextoNovo := ATextoNovo;
  NomeSingular := ANomeSingular;
  Result := Self;
end;

function TTabelaDef.Filtro(const ACampo, ATodos, ASQL: string): TTabelaDef;
begin
  FiltroCampo := ACampo;
  FiltroTodos := ATodos;
  FiltroSQL := ASQL;
  Result := Self;
end;

function TTabelaDef.Detalhe(const ARotulo, ATabela: string;
  const ALigacoes: array of string): TTabelaDef;
var
  N, I: Integer;
begin
  N := Length(Detalhes);
  SetLength(Detalhes, N + 1);
  Detalhes[N].Rotulo := ARotulo;
  Detalhes[N].Tabela := ATabela;
  SetLength(Detalhes[N].Ligacoes, Length(ALigacoes) div 2);
  for I := 0 to High(Detalhes[N].Ligacoes) do
  begin
    Detalhes[N].Ligacoes[I].CampoDetalhe := ALigacoes[I * 2];
    Detalhes[N].Ligacoes[I].CampoMestre := ALigacoes[I * 2 + 1];
  end;
  Result := Self;
end;

function Nova(const ATabela, ATitulo, AChave, AAlias: string): TTabelaDef;
begin
  Result := TTabelaDef.Create;
  Result.Tabela := ATabela;
  Result.Titulo := ATitulo;
  Result.Chave := AChave;
  Result.Alias := AAlias;
  FDefinicoes.AddObject(ATabela, Result);
end;

{ Tabelas simples "código + descrição" }
function NovaSimples(const ATabela, ATitulo, ARotulo, ACodigo,
  ADescricao: string; ALargura: Integer;
  const ATextoDescricao, ATextoNovo, ANomeSingular: string): TTabelaDef;
begin
  Result := Nova(ATabela, ATitulo, ACodigo, 'a');
  Result.SQLGrid := Format('SELECT a.%s, a.%s FROM %s a', [ACodigo, ADescricao, ATabela]);
  Result.CampoBusca := 'a.' + ADescricao;
  Result.Ordem := 'a.' + ADescricao;
  Result.RotuloRegistro := ARotulo;
  Result.CampoDescricao := ADescricao;
  Result
    .Campo(ACodigo, 'Código', tcInteiro, 80, [ocSomenteLeitura])
    .Campo(ADescricao, 'Descrição', tcTexto, ALargura, [ocObrigatorio])
    .Coluna(ACodigo, 'Código', 70, ecSuave)
    .Coluna(ADescricao, 'Descrição', ALargura, ecDestaque)
    .Apresentar('TABELAS AUXILIARES', ATextoDescricao, ATextoNovo, ANomeSingular);
end;

function Definicao(const ATabela: string): TTabelaDef;
var
  I: Integer;
begin
  I := FDefinicoes.IndexOf(ATabela);
  if I < 0 then
    raise Exception.CreateFmt('Tabela sem definição: %s', [ATabela]);
  Result := TTabelaDef(FDefinicoes.Objects[I]);
end;

procedure CriarDefinicoes;
begin
  with Nova('usuario', 'Usuários', 'usuario_codigo', 'u') do
  begin
    SQLGrid := 'SELECT u.usuario_codigo, u.usuario_nome, u.usuario_login, u.usuario_email, ' +
      'CASE u.usuario_perfil WHEN 1 THEN ''ADMINISTRADOR'' WHEN 2 THEN ''OPERADOR'' ' +
      'ELSE ''CONSULTA'' END AS perfil_descricao, ' +
      'CASE u.usuario_ativo WHEN 1 THEN ''ATIVO'' ELSE ''INATIVO'' END AS ativo_descricao, ' +
      'u.usuario_ultimo_acesso FROM usuario u';
    CampoBusca := 'CONCAT(u.usuario_nome, '' '', u.usuario_login, '' '', COALESCE(u.usuario_email, ''''))';
    Ordem := 'u.usuario_nome';
    RotuloRegistro := 'Usuário';
    CampoDescricao := 'usuario_nome';
    Coluna('usuario_nome', 'Nome', 260, ecDestaque)
      .Coluna('usuario_login', 'Login', 140)
      .Coluna('usuario_email', 'E-mail', 220, ecSuave)
      .Coluna('perfil_descricao', 'Perfil', 130)
      .Coluna('ativo_descricao', 'Situação', 90)
      .Coluna('usuario_ultimo_acesso', 'Último acesso', 120, ecSuave)
      .Apresentar('SISTEMA', 'Pessoas com acesso ao sistema e o que cada uma pode fazer.',
        'Novo usuário', 'usuário')
      .Filtro('u.usuario_perfil', 'Todos os perfis',
        'SELECT 1 AS codigo, ''ADMINISTRADOR'' AS descricao UNION ALL ' +
        'SELECT 2, ''OPERADOR'' UNION ALL SELECT 3, ''CONSULTA''');
  end;

  NovaSimples('armazenagem', 'Locais de Armazenagem', 'Local', 'armazenagem_codigo', 'armazenagem_descricao', 400,
    'Onde os exemplares estão guardados: estantes, caixas, gavetas.', 'Novo local', 'local');
  NovaSimples('editora', 'Editoras', 'Editora', 'editora_codigo', 'editora_descricao', 400,
    'Editoras que publicaram os títulos do acervo.', 'Nova editora', 'editora');
  NovaSimples('situacao_titulo', 'Situações de Título', 'Situação', 'situacao_codigo', 'situacao_descricao', 400,
    'Situação editorial de cada título: encerrado, cancelado, em publicação...', 'Nova situação', 'situação');
  NovaSimples('tipo_titulo', 'Tipos de Título', 'Tipo', 'tipotitulo_codigo', 'tipotitulo_descricao', 400,
    'Formatos editoriais: minissérie, periódico, especial, encadernado...', 'Novo tipo', 'tipo');
  NovaSimples('universo', 'Universos', 'Universo', 'universo_codigo', 'universo_descricao', 400,
    'Universos ficcionais aos quais os personagens pertencem.', 'Novo universo', 'universo');

  with Nova('tamanho', 'Tamanhos / Formatos', 'tamanho_codigo', 'a') do
  begin
    SQLGrid := 'SELECT a.tamanho_codigo, a.tamanho_descricao, a.tamanho_linha, a.tamanho_coluna FROM tamanho a';
    CampoBusca := 'a.tamanho_descricao';
    Ordem := 'a.tamanho_descricao';
    RotuloRegistro := 'Tamanho';
    CampoDescricao := 'tamanho_descricao';
    Campo('tamanho_codigo', 'Código', tcInteiro, 80, [ocSomenteLeitura])
      .Campo('tamanho_descricao', 'Descrição', tcTexto, 400, [ocObrigatorio])
      .Campo('tamanho_linha', 'Linha (cm)', tcDecimal, 100)
      .Campo('tamanho_coluna', 'Coluna (cm)', tcDecimal, 100)
      .Coluna('tamanho_codigo', 'Código', 70, ecSuave)
      .Coluna('tamanho_descricao', 'Descrição', 350, ecDestaque)
      .Coluna('tamanho_linha', 'Linha', 80, ecNumero)
      .Coluna('tamanho_coluna', 'Coluna', 80, ecNumero)
      .Apresentar('TABELAS AUXILIARES', 'Formatos físicos das revistas e suas medidas.',
        'Novo tamanho', 'tamanho');
  end;

  with Nova('artista', 'Artistas', 'artista_codigo', 'a') do
  begin
    SQLGrid := 'SELECT a.artista_codigo, a.artista_nome, a.artista_historico, a.artista_foto FROM artista a';
    CampoBusca := 'a.artista_nome';
    Ordem := 'a.artista_nome';
    RotuloRegistro := 'Artista';
    CampoDescricao := 'artista_nome';
    Campo('artista_codigo', 'Código', tcInteiro, 80, [ocSomenteLeitura])
      .Campo('artista_nome', 'Nome', tcTexto, 400, [ocObrigatorio])
      .Campo('artista_foto', 'Foto (arquivo)', tcImagem, 400)
      .Campo('artista_historico', 'Histórico', tcMemo, 820)
      .Coluna('artista_codigo', 'Código', 70, ecSuave)
      .Coluna('artista_nome', 'Nome', 300, ecDestaque)
      .Coluna('artista_historico', 'Histórico', 450, ecSuave)
      .Apresentar('CADASTROS', 'Roteiristas, desenhistas, arte-finalistas e demais criadores.',
        'Novo artista', 'artista')
      .Detalhe('Personagens criados', 'personagem_criador', ['artista_codigo', 'artista_codigo']);
  end;

  with Nova('personagem', 'Personagens', 'personagem_codigo', 'p') do
  begin
    SQLGrid := 'SELECT p.personagem_codigo, p.personagem_descricao, u.universo_descricao, p.personagem_origem ' +
      'FROM personagem p LEFT JOIN universo u ON u.universo_codigo = p.universo_codigo';
    CampoBusca := 'p.personagem_descricao';
    Ordem := 'p.personagem_descricao';
    RotuloRegistro := 'Personagem';
    CampoDescricao := 'personagem_descricao';
    Campo('personagem_codigo', 'Código', tcInteiro, 80, [ocSomenteLeitura])
      .Campo('personagem_descricao', 'Nome', tcTexto, 400, [ocObrigatorio])
      .Campo('universo_codigo', 'Universo', tcLookup, 250, [ocObrigatorio], SQL_UNIVERSO)
      .Campo('personagem_origem', 'Origem', tcMemo, 820)
      .Coluna('personagem_codigo', 'Código', 70, ecSuave)
      .Coluna('personagem_descricao', 'Nome', 300, ecDestaque)
      .Coluna('universo_descricao', 'Universo', 150)
      .Coluna('personagem_origem', 'Origem', 400, ecSuave)
      .Apresentar('CADASTROS', 'Heróis, vilões e equipes, organizados por universo.',
        'Novo personagem', 'personagem')
      .Filtro('p.universo_codigo', 'Todos os universos', SQL_UNIVERSO)
      .Detalhe('Criadores', 'personagem_criador', ['personagem_codigo', 'personagem_codigo'])
      .Detalhe('Imagens', 'imagempersonagem', ['personagem_codigo', 'personagem_codigo']);
  end;

  with Nova('personagem_criador', 'Criadores de Personagens', 'id', 'pc') do
  begin
    SQLGrid := 'SELECT pc.id, p.personagem_descricao, a.artista_nome FROM personagem_criador pc ' +
      'JOIN personagem p ON p.personagem_codigo = pc.personagem_codigo ' +
      'JOIN artista a ON a.artista_codigo = pc.artista_codigo';
    CampoBusca := 'CONCAT(p.personagem_descricao, '' '', a.artista_nome)';
    Ordem := 'p.personagem_descricao, a.artista_nome';
    RotuloRegistro := 'Criação';
    CampoDescricao := 'id';
    Campo('personagem_codigo', 'Personagem', tcLookup, 350, [ocObrigatorio], SQL_PERSONAGEM)
      .Campo('artista_codigo', 'Artista (criador)', tcLookup, 350, [ocObrigatorio], SQL_ARTISTA)
      .Coluna('personagem_descricao', 'Personagem', 350, ecDestaque)
      .Coluna('artista_nome', 'Artista', 350)
      .Apresentar('CADASTROS', 'Artistas responsáveis pela criação do personagem.',
        'Adicionar criador', 'criador');
  end;

  with Nova('imagempersonagem', 'Imagens do Personagem', 'id', 'i') do
  begin
    SQLGrid := 'SELECT i.id, i.imagem_codigo, i.imagem_descricao FROM imagempersonagem i';
    CampoBusca := 'i.imagem_descricao';
    Ordem := 'i.imagem_codigo';
    RotuloRegistro := 'Imagem';
    CampoDescricao := 'imagem_codigo';
    Campo('imagem_codigo', 'Nº', tcInteiro, 80, [ocAutoNumero])
      .Campo('imagem_descricao', 'Descrição / arquivo', tcImagem, 500)
      .Coluna('imagem_codigo', 'Nº', 60, ecNumero)
      .Coluna('imagem_descricao', 'Descrição / arquivo', 500, ecDestaque)
      .Apresentar('CADASTROS', 'Imagens de referência do personagem.', 'Nova imagem', 'imagem');
  end;

  with Nova('titulo', 'Títulos', 'titulo_codigo', 't') do
  begin
    SQLGrid := 'SELECT t.titulo_codigo, t.titulo_descricao, e.editora_descricao, tt.tipotitulo_descricao, ' +
      's.situacao_descricao, t.titulo_periodicidade, t.titulo_origem, ' +
      '(SELECT COUNT(*) FROM exemplar x WHERE x.titulo_codigo = t.titulo_codigo) AS qtd_exemplares ' +
      'FROM titulo t ' +
      'LEFT JOIN editora e ON e.editora_codigo = t.editora_codigo ' +
      'LEFT JOIN tipo_titulo tt ON tt.tipotitulo_codigo = t.tipotitulo_codigo ' +
      'LEFT JOIN situacao_titulo s ON s.situacao_codigo = t.situacao_codigo';
    CampoBusca := 't.titulo_descricao';
    Ordem := 't.titulo_descricao';
    RotuloRegistro := 'Título';
    CampoDescricao := 'titulo_descricao';
    Campo('titulo_codigo', 'Código', tcInteiro, 80, [ocSomenteLeitura])
      .Campo('titulo_descricao', 'Título', tcTexto, 420, [ocObrigatorio])
      .Campo('editora_codigo', 'Editora', tcLookup, 280, [ocObrigatorio], SQL_EDITORA)
      .Campo('tipotitulo_codigo', 'Tipo', tcLookup, 250, [ocObrigatorio], SQL_TIPO_TITULO)
      .Campo('situacao_codigo', 'Situação', tcLookup, 200, [ocObrigatorio], SQL_SITUACAO)
      .Campo('titulo_periodicidade', 'Periodicidade', tcInteiro, 100)
      .Campo('titulo_origem', 'Origem (país)', tcTexto, 200)
      .Coluna('titulo_descricao', 'Título', 330, ecDestaque)
      .Coluna('editora_descricao', 'Editora', 140)
      .Coluna('tipotitulo_descricao', 'Tipo', 150)
      .Coluna('situacao_descricao', 'Situação', 110)
      .Coluna('titulo_origem', 'Origem', 80, ecSuave)
      .Coluna('qtd_exemplares', 'Exemplares', 80, ecNumero)
      .Apresentar('ACERVO', 'Revistas e séries do acervo. Abra os exemplares de cada título ' +
        'para cadastrar as edições e suas histórias.', 'Novo título', 'título')
      .Filtro('t.editora_codigo', 'Todas as editoras', SQL_EDITORA)
      .Detalhe('Exemplares', 'exemplar', ['titulo_codigo', 'titulo_codigo']);
  end;

  with Nova('exemplar', 'Exemplares', 'id', 'x') do
  begin
    SQLGrid := 'SELECT x.id, x.exemplar_codigo, x.exemplar_subtitulo, x.exemplar_data, ' +
      'tm.tamanho_descricao, ar.armazenagem_descricao, x.exemplar_numeropagina, ' +
      CASE_SITUACAO_EXEMPLAR + ' AS situacao_descricao ' +
      'FROM exemplar x ' +
      'LEFT JOIN tamanho tm ON tm.tamanho_codigo = x.tamanho_codigo ' +
      'LEFT JOIN armazenagem ar ON ar.armazenagem_codigo = x.armazenagem_codigo';
    CampoBusca := 'CONCAT(x.exemplar_codigo, '' '', COALESCE(x.exemplar_subtitulo, ''''))';
    Ordem := 'x.exemplar_codigo';
    RotuloRegistro := 'Nº';
    CampoDescricao := 'exemplar_codigo';
    Campo('exemplar_codigo', 'Número', tcInteiro, 90, [ocObrigatorio, ocAutoNumero])
      .Campo('exemplar_subtitulo', 'Subtítulo', tcTexto, 520)
      .Campo('exemplar_data', 'Data', tcData, 130)
      .Campo('tamanho_codigo', 'Tamanho', tcLookup, 220, [], SQL_TAMANHO)
      .Campo('armazenagem_codigo', 'Armazenagem', tcLookup, 220, [], SQL_ARMAZENAGEM).Padrao(1)
      .Campo('exemplar_situacao', 'Situação', tcLookup, 160, [], SQL_SITUACAO_EXEMPLAR).Padrao(1)
      .Campo('exemplar_numeropagina', 'Nº de páginas', tcInteiro, 100)
      .Campo('exemplar_capa', 'Capa (arquivo)', tcImagem, 420)
      .Coluna('exemplar_codigo', 'Nº', 60, ecDestaque)
      .Coluna('exemplar_subtitulo', 'Subtítulo', 300)
      .Coluna('exemplar_data', 'Data', 90, ecSuave)
      .Coluna('tamanho_descricao', 'Tamanho', 120)
      .Coluna('armazenagem_descricao', 'Armazenagem', 130)
      .Coluna('exemplar_numeropagina', 'Páginas', 70, ecNumero)
      .Coluna('situacao_descricao', 'Situação', 100)
      .Apresentar('ACERVO', 'Edições (números) do título selecionado.', 'Novo exemplar', 'exemplar')
      .Filtro('x.tamanho_codigo', 'Todos os tamanhos', SQL_TAMANHO)
      .Detalhe('Histórias', 'historia', ['titulo_codigo', 'titulo_codigo',
                                          'exemplar_codigo', 'exemplar_codigo']);
  end;

  with Nova('historia', 'Histórias', 'id', 'h') do
  begin
    SQLGrid := 'SELECT h.id, h.historia_numero, h.historia_titulo, h.historia_original, ' +
      CASE_COR_HISTORIA + ' AS cor_descricao, h.historia_resumo FROM historia h';
    CampoBusca := 'h.historia_titulo';
    Ordem := 'h.historia_numero';
    RotuloRegistro := 'História';
    CampoDescricao := 'historia_titulo';
    Campo('historia_numero', 'Número', tcInteiro, 90, [ocObrigatorio, ocAutoNumero])
      .Campo('historia_titulo', 'Título', tcTexto, 400, [ocObrigatorio])
      .Campo('historia_cor', 'Cor', tcLookup, 180, [ocObrigatorio], SQL_COR_HISTORIA).Padrao(0)
      .Campo('historia_original', 'Título original', tcTexto, 400)
      .Campo('historia_resumo', 'Resumo', tcMemo, 820)
      .Coluna('historia_numero', 'Nº', 50, ecNumero)
      .Coluna('historia_titulo', 'Título', 300, ecDestaque)
      .Coluna('historia_original', 'Título original', 250, ecSuave)
      .Coluna('cor_descricao', 'Cor', 120)
      .Apresentar('ACERVO', 'Histórias publicadas neste exemplar.', 'Nova história', 'história')
      .Detalhe('Artistas', 'artista_historia', ['titulo_codigo', 'titulo_codigo',
                                                 'exemplar_codigo', 'exemplar_codigo',
                                                 'historia_codigo', 'historia_numero'])
      .Detalhe('Personagens', 'historiapersonagem', ['titulo_codigo', 'titulo_codigo',
                                                      'exemplar_codigo', 'exemplar_codigo',
                                                      'historia_codigo', 'historia_numero']);
  end;

  with Nova('artista_historia', 'Artistas da História', 'id', 'ah') do
  begin
    SQLGrid := 'SELECT ah.id, a.artista_nome, ' + CASE_PARTICIPACAO + ' AS participacao ' +
      'FROM artista_historia ah JOIN artista a ON a.artista_codigo = ah.artista_codigo';
    CampoBusca := 'a.artista_nome';
    Ordem := 'ah.participa_artistahistoria, a.artista_nome';
    RotuloRegistro := 'Participação';
    CampoDescricao := 'id';
    Campo('artista_codigo', 'Artista', tcLookup, 350, [ocObrigatorio], SQL_ARTISTA)
      .Campo('participa_artistahistoria', 'Participação', tcLookup, 200, [], SQL_PARTICIPACAO)
      .Coluna('artista_nome', 'Artista', 350, ecDestaque)
      .Coluna('participacao', 'Participação', 200)
      .Apresentar('ACERVO', 'Equipe criativa da história.', 'Adicionar artista', 'participação')
      .Filtro('ah.participa_artistahistoria', 'Todas as funções', SQL_PARTICIPACAO);
  end;

  with Nova('historiapersonagem', 'Personagens da História', 'id', 'hp') do
  begin
    SQLGrid := 'SELECT hp.id, p.personagem_descricao, u.universo_descricao FROM historiapersonagem hp ' +
      'JOIN personagem p ON p.personagem_codigo = hp.personagem_codigo ' +
      'LEFT JOIN universo u ON u.universo_codigo = p.universo_codigo';
    CampoBusca := 'p.personagem_descricao';
    Ordem := 'p.personagem_descricao';
    RotuloRegistro := 'Personagem';
    CampoDescricao := 'id';
    Campo('personagem_codigo', 'Personagem', tcLookup, 350, [ocObrigatorio], SQL_PERSONAGEM)
      .Coluna('personagem_descricao', 'Personagem', 350, ecDestaque)
      .Coluna('universo_descricao', 'Universo', 200)
      .Apresentar('ACERVO', 'Personagens que aparecem na história.', 'Adicionar personagem', 'personagem');
  end;
end;

initialization
  FDefinicoes := TStringList.Create;
  FDefinicoes.OwnsObjects := True;
  CriarDefinicoes;

finalization
  FDefinicoes.Free;

end.
