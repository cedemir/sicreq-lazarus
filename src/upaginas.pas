unit uPaginas;

{ Páginas fixas do menu lateral: Painel, Relatórios e Configurações. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Math, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  LazUTF8, ZDataset, uTema, uEscolha;

type
  TEventoAbrir = procedure(const ATabela: string) of object;

  { TPaginaBase - cabeçalho padrão (seção, título, descrição) }

  TPaginaBase = class(TPanel)
  protected
    Cabecalho: TPanel;
    Area: TPanel;     // conteúdo abaixo do cabeçalho
  public
    constructor Criar(AOwner: TComponent; AParent: TWinControl;
      const ASecao, ATitulo, ADescricao: string); virtual;
  end;

  { TPaginaPainel }

  TPaginaPainel = class(TPaginaBase)
  private
    FOnAbrir: TEventoAbrir;
    FCartoes: array of TCartao;
    FListaTop: TCartao;
    procedure AreaResize(Sender: TObject);
    procedure BtnAbrirClick(Sender: TObject);
    procedure MontarIndicadores;
    procedure MontarMaisExemplares;
  public
    constructor Criar(AOwner: TComponent; AParent: TWinControl;
      AOnAbrir: TEventoAbrir); reintroduce;
  end;

  { TPaginaRelatorios }

  TPaginaRelatorios = class(TPaginaBase)
  private
    FTituloFicha: TCaixaEscolha;
    procedure BtnGerarClick(Sender: TObject);
    procedure BtnFichaClick(Sender: TObject);
    procedure MontarFicha;
  public
    constructor Criar(AOwner: TComponent; AParent: TWinControl); reintroduce;
  end;

  { TPaginaConfiguracoes }

  TPaginaConfiguracoes = class(TPaginaBase)
  private
    FOnAlterada: TNotifyEvent;
    FValores: TCartao;
    procedure MontarValores;
    procedure BtnAlterarClick(Sender: TObject);
    procedure BtnSenhaClick(Sender: TObject);
  public
    constructor Criar(AOwner: TComponent; AParent: TWinControl;
      AOnAlterada: TNotifyEvent); reintroduce;
  end;

implementation

uses
  uDM, uConfig, uRelatorios, uSessao, uMinhaSenha;

const
  { indicadores do painel: rótulo, SQL de contagem, tabela aberta pelo botão }
  INDICADORES: array[0..5, 0..2] of string = (
    ('Títulos',     'SELECT COUNT(*) FROM titulo',     'titulo'),
    ('Exemplares',  'SELECT COUNT(*) FROM exemplar',   'titulo'),
    ('Histórias',   'SELECT COUNT(*) FROM historia',   'titulo'),
    ('Artistas',    'SELECT COUNT(*) FROM artista',    'artista'),
    ('Personagens', 'SELECT COUNT(*) FROM personagem', 'personagem'),
    ('Editoras',    'SELECT COUNT(*) FROM editora',    'editora'));

  RELATORIOS: array[0..4, 0..1] of string = (
    ('Títulos por editora',
     'Todos os títulos agrupados por editora, com tipo, situação e quantidade de exemplares.'),
    ('Acervo: exemplares por título',
     'Lista de exemplares de cada título, com data, tamanho, armazenagem e páginas.'),
    ('Histórias com artistas e personagens',
     'Cada edição com suas histórias, a equipe criativa e os personagens (paisagem).'),
    ('Personagens por universo',
     'Personagens agrupados por universo, com a origem de cada um.'),
    ('Criadores de personagens',
     'Artistas e os personagens que criaram.'));

{ TPaginaBase }

constructor TPaginaBase.Criar(AOwner: TComponent; AParent: TWinControl;
  const ASecao, ATitulo, ADescricao: string);
begin
  inherited Create(AOwner);
  Parent := AParent;
  Align := alClient;
  BevelOuter := bvNone;
  Color := corFundo;
  ParentColor := False;
  BorderSpacing.Left := 34;
  BorderSpacing.Right := 34;
  BorderSpacing.Top := 26;
  BorderSpacing.Bottom := 24;

  Cabecalho := NovoPainel(Self, Self, alTop, corFundo, 112);
  NovoRotulo(Self, Cabecalho, UTF8UpperCase(ASecao), 9, corDestaque, True).SetBounds(0, 2, 600, 18);
  NovoRotulo(Self, Cabecalho, ATitulo, 24, corTexto, True).SetBounds(0, 24, 900, 44);
  NovoRotulo(Self, Cabecalho, ADescricao, 11, corTextoSuave).SetBounds(0, 76, 1100, 24);

  Area := NovoPainel(Self, Self, alClient, corFundo, 0);
  Area.BorderSpacing.Top := 22;
end;

{ TPaginaPainel }

constructor TPaginaPainel.Criar(AOwner: TComponent; AParent: TWinControl;
  AOnAbrir: TEventoAbrir);
begin
  inherited Criar(AOwner, AParent, 'Visão geral', 'Painel',
    'Resumo do acervo armazenado no banco de dados.');
  FOnAbrir := AOnAbrir;
  MontarIndicadores;
  MontarMaisExemplares;
  Area.OnResize := @AreaResize;
  AreaResize(nil);
end;

procedure TPaginaPainel.MontarIndicadores;
var
  I: Integer;
  C: TCartao;
  B: TBotao;
  V: Variant;
  Lbl: TLabel;
begin
  SetLength(FCartoes, Length(INDICADORES));
  for I := 0 to High(INDICADORES) do
  begin
    C := NovoCartao(Self, Area, corFundo);
    C.Height := 150;
    FCartoes[I] := C;

    NovoRotulo(Self, C, UTF8UpperCase(INDICADORES[I, 0]), 9, corTextoSuave, True).SetBounds(22, 20, 220, 18);
    try
      V := DM.ValorSQL(INDICADORES[I, 1], []);
    except
      V := 0;
    end;
    Lbl := NovoRotulo(Self, C, FormatFloat('#,##0', V), 28, corTexto, True);
    if I in [1, 2] then
      Lbl.Font.Color := corNumero;
    Lbl.SetBounds(22, 44, 220, 48);

    B := NovoBotao(Self, C, 'Abrir  ›', ebSecundario, @BtnAbrirClick, corCartao);
    B.Tag := I;
    B.Font.Size := 9;
    B.SetBounds(22, 100, 90, 32);
  end;
end;

procedure TPaginaPainel.MontarMaisExemplares;
var
  Q: TZReadOnlyQuery;
  Y: Integer;
  Lbl: TLabel;
  Linha: TPanel;
begin
  FListaTop := NovoCartao(Self, Area, corFundo);
  NovoRotulo(Self, FListaTop, 'TÍTULOS COM MAIS EXEMPLARES', 9, corTextoSuave, True).SetBounds(22, 20, 400, 18);
  Q := DM.NovaConsulta(nil,
    'SELECT t.titulo_descricao, e.editora_descricao, COUNT(*) AS qtd ' +
    'FROM exemplar x JOIN titulo t ON t.titulo_codigo = x.titulo_codigo ' +
    'JOIN editora e ON e.editora_codigo = t.editora_codigo ' +
    'GROUP BY t.titulo_codigo, t.titulo_descricao, e.editora_descricao ' +
    'ORDER BY qtd DESC LIMIT 6');
  try
    Q.Open;
    Y := 50;
    if Q.IsEmpty then
      NovoRotulo(Self, FListaTop, 'Nenhum exemplar cadastrado ainda.', 10, corTextoSuave).SetBounds(22, Y, 400, 20);
    while not Q.EOF do
    begin
      Linha := NovoPainel(Self, FListaTop, alNone, corBorda, 1);
      Linha.SetBounds(22, Y, 2000, 1);
      Lbl := NovoRotulo(Self, FListaTop, Q.FieldByName('titulo_descricao').AsString, 10, clWhite, True);
      Lbl.SetBounds(22, Y + 12, 520, 20);
      Lbl := NovoRotulo(Self, FListaTop, Q.FieldByName('editora_descricao').AsString, 10, corTexto);
      Lbl.SetBounds(560, Y + 12, 260, 20);
      Lbl := NovoRotulo(Self, FListaTop, Q.FieldByName('qtd').AsString + ' exemplares', 10, corNumero, True);
      Lbl.SetBounds(840, Y + 12, 200, 20);
      Inc(Y, 44);
      Q.Next;
    end;
    FListaTop.Height := Max(Y + 16, 110);
  finally
    Q.Free;
  end;
end;

procedure TPaginaPainel.AreaResize(Sender: TObject);
const
  ESPACO = 20;
var
  I, Colunas, W, Linha, Col: Integer;
begin
  if Area.ClientWidth < 700 then
    Colunas := 2
  else
    Colunas := 3;
  W := (Area.ClientWidth - (Colunas - 1) * ESPACO) div Colunas;
  for I := 0 to High(FCartoes) do
  begin
    Linha := I div Colunas;
    Col := I mod Colunas;
    FCartoes[I].SetBounds(Col * (W + ESPACO), Linha * (150 + ESPACO), W, 150);
  end;
  Linha := (Length(FCartoes) + Colunas - 1) div Colunas;
  FListaTop.SetBounds(0, Linha * (150 + ESPACO), Area.ClientWidth, FListaTop.Height);
end;

procedure TPaginaPainel.BtnAbrirClick(Sender: TObject);
begin
  if Assigned(FOnAbrir) then
    FOnAbrir(INDICADORES[TComponent(Sender).Tag, 2]);
end;

{ TPaginaRelatorios }

constructor TPaginaRelatorios.Criar(AOwner: TComponent; AParent: TWinControl);
var
  I: Integer;
  C: TCartao;
  B: TBotao;
begin
  inherited Criar(AOwner, AParent, 'Fortes Report', 'Relatórios',
    'Gere a pré-visualização para imprimir ou salvar em PDF.');
  MontarFicha;
  for I := 0 to High(RELATORIOS) do
  begin
    C := NovoCartao(Self, Area, corFundo);
    C.Align := alTop;
    C.Height := 92;
    C.Top := 200 + I * 200;
    C.BorderSpacing.Bottom := 14;
    NovoRotulo(Self, C, RELATORIOS[I, 0], 12, clWhite, True).SetBounds(24, 18, 700, 24);
    NovoRotulo(Self, C, RELATORIOS[I, 1], 10, corTextoSuave).SetBounds(24, 50, 900, 20);
    B := NovoBotao(Self, C, 'Gerar relatório', ebPrimario, @BtnGerarClick, corCartao);
    B.Tag := I;
    B.Height := 40;
    B.Top := 26;
    B.AnchorSide[akRight].Control := C;
    B.AnchorSide[akRight].Side := asrRight;
    B.BorderSpacing.Right := 24;
    B.Anchors := [akTop, akRight];
  end;
end;

procedure TPaginaRelatorios.MontarFicha;
var
  C: TCartao;
  B: TBotao;
  Q: TZReadOnlyQuery;
begin
  C := NovoCartao(Self, Area, corFundo);
  C.Align := alTop;
  C.Height := 92;
  C.Top := 0;
  C.BorderSpacing.Bottom := 14;
  NovoRotulo(Self, C, 'Ficha do título', 12, clWhite, True).SetBounds(24, 18, 300, 24);
  NovoRotulo(Self, C, 'Dados do título e, por exemplar, as histórias com artistas e personagens.',
    10, corTextoSuave).SetBounds(24, 50, 560, 20);

  B := NovoBotao(Self, C, 'Gerar ficha', ebPrimario, @BtnFichaClick, corCartao);
  B.Height := 40;
  B.Top := 26;
  B.AnchorSide[akRight].Control := C;
  B.AnchorSide[akRight].Side := asrRight;
  B.BorderSpacing.Right := 24;
  B.Anchors := [akTop, akRight];

  FTituloFicha := TCaixaEscolha.Create(Self);
  FTituloFicha.Parent := C;
  FTituloFicha.CorFundo := corCartao;
  FTituloFicha.TextoVazio := 'Escolha o título...';
  FTituloFicha.Width := 380;
  FTituloFicha.Top := 25;
  FTituloFicha.AnchorSide[akRight].Control := B;
  FTituloFicha.AnchorSide[akRight].Side := asrLeft;
  FTituloFicha.BorderSpacing.Right := 12;
  FTituloFicha.Anchors := [akTop, akRight];
  Q := DM.NovaConsulta(nil, 'SELECT titulo_codigo AS codigo, titulo_descricao AS descricao ' +
    'FROM titulo WHERE EXISTS (SELECT 1 FROM exemplar x WHERE x.titulo_codigo = titulo.titulo_codigo) ' +
    'ORDER BY titulo_descricao');
  try
    Q.Open;
    FTituloFicha.CarregarDe(Q);
  finally
    Q.Free;
  end;
end;

procedure TPaginaRelatorios.BtnFichaClick(Sender: TObject);
begin
  if VarIsNull(FTituloFicha.Valor) then
  begin
    Avisar('Ficha do título', 'Escolha o título (só aparecem títulos com exemplares).');
    Exit;
  end;
  RelFichaTitulo(FTituloFicha.Valor);
end;

procedure TPaginaRelatorios.BtnGerarClick(Sender: TObject);
begin
  case TComponent(Sender).Tag of
    0: RelTitulosPorEditora;
    1: RelAcervoPorTitulo;
    2: RelHistorias;
    3: RelPersonagensPorUniverso;
    4: RelCriadores;
  end;
end;

{ TPaginaConfiguracoes }

constructor TPaginaConfiguracoes.Criar(AOwner: TComponent; AParent: TWinControl;
  AOnAlterada: TNotifyEvent);
begin
  inherited Criar(AOwner, AParent, 'Sistema', 'Configurações',
    'Conexão com o banco MySQL (gravada em sicreq.ini ao lado do executável).');
  FOnAlterada := AOnAlterada;
  MontarValores;
end;

procedure TPaginaConfiguracoes.MontarValores;
var
  Itens: array[0..6, 0..1] of string;
  I, X: Integer;
  B: TBotao;
begin
  FreeAndNil(FValores);
  FValores := NovoCartao(Self, Area, corFundo);
  FValores.Align := alTop;
  FValores.Height := 24 + 7 * 40 + 80;

  Itens[0, 0] := 'Servidor';    Itens[0, 1] := DM.Config.Host;
  Itens[1, 0] := 'Porta';       Itens[1, 1] := IntToStr(DM.Config.Porta);
  Itens[2, 0] := 'Banco';       Itens[2, 1] := DM.Config.Banco;
  Itens[3, 0] := 'Usuário';     Itens[3, 1] := DM.Config.Usuario;
  Itens[4, 0] := 'Biblioteca';  Itens[4, 1] := DM.Config.Biblioteca;
  Itens[5, 0] := 'Servidor MySQL';
  if DM.Conexao.Connected then
    Itens[5, 1] := DM.Conexao.ServerVersionStr
  else
    Itens[5, 1] := 'desconectado';
  Itens[6, 0] := 'Arquivo';     Itens[6, 1] := DM.ArquivoIni;

  for I := 0 to High(Itens) do
  begin
    NovoRotulo(Self, FValores, UTF8UpperCase(Itens[I, 0]), 9, corTextoSuave, True).SetBounds(24, 24 + I * 40 + 4, 180, 18);
    NovoRotulo(Self, FValores, Itens[I, 1], 11, corTexto).SetBounds(210, 24 + I * 40, 900, 22);
  end;

  B := NovoBotao(Self, FValores, 'Alterar minha senha', ebSecundario, @BtnSenhaClick, corCartao);
  B.SetBounds(24, 24 + 7 * 40 + 14, B.Width, 42);
  { a conexão vale para o computador inteiro: só administrador altera }
  if EhAdministrador then
  begin
    X := B.Left + B.Width + 12;
    B := NovoBotao(Self, FValores, 'Alterar conexão', ebPrimario, @BtnAlterarClick, corCartao);
    B.SetBounds(X, 24 + 7 * 40 + 14, B.Width, 42);
  end;
end;

procedure TPaginaConfiguracoes.BtnSenhaClick(Sender: TObject);
begin
  AlterarMinhaSenha;
end;

procedure TPaginaConfiguracoes.BtnAlterarClick(Sender: TObject);
begin
  if not EditarConfiguracao then
    Exit;
  try
    DM.Conectar;
  except
    on E: Exception do
      Avisar('Falha ao reconectar', E.Message);
  end;
  { a janela principal recria esta página e atualiza o cabeçalho }
  if Assigned(FOnAlterada) then
    FOnAlterada(Self);
end;

end.
