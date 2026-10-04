unit uCadastro;

{ Página de cadastro (listagem).

  O visual de cada tabela é um TFrame desenhado no designer, em
  src/telas/ulista<tabela>.pas/.lfm (registrado em uTelas). Esta unit
  cria o frame dentro da área de conteúdo e "adota" os componentes pelo
  nome, ligando o comportamento comum a todas as tabelas:

    QryLista / DsLista  consulta da listagem (SQL vem de uDefinicoes)
    Grid                tabela; a coluna com Tag = 100 recebe os botões
                        de ação (detalhes, Editar, Excluir / Ver)
    EdtBusca            pesquisa enquanto digita
    CbFiltro            (opcional) vira a combo escura do filtro
    BtnNovo, BtnImprimir, BtnVoltar, PnlTrilha, LblTrilha, LblContagem

  Os botões de detalhe (ex.: "Exemplares") pedem à janela principal que
  empilhe a página filha, que mostra PnlTrilha com "‹ Voltar". }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Variants, StrUtils, Math, Forms, Controls, StdCtrls,
  ExtCtrls, Graphics, Grids, DBGrids, DB, LCLType, LazUTF8, ZDataset,
  uDefinicoes, uTema, uTemaForm, uEscolha, uSessao, uTelas;

type
  TEventoDetalhe = procedure(const ATabela: string; const AFixos: TFiltrosFixos;
    const ATrilha: string) of object;

  TRetangulos = array of TRect;

  { TPaginaCadastro }

  TPaginaCadastro = class(TPanel)
  private
    FDef: TTabelaDef;
    FFixos: TFiltrosFixos;
    FTrilha: string;
    FOnDetalhe: TEventoDetalhe;
    FOnVoltar: TNotifyEvent;
    FMouseX, FMouseY: Integer;
    FSomenteLeitura: Boolean;       // perfil Consulta
    FAcoes: array of string;        // textos dos botões da coluna AÇÕES

    FFrame: TCustomFrame;          // a tela desenhada (src/telas)
    QryGrid: TZReadOnlyQuery;
    DsGrid: TDataSource;
    Grid: TDBGrid;
    EdtBusca: TEdit;
    CmbFiltro: TCaixaEscolha;
    LblContagem: TLabel;
    TmrBusca: TTimer;

    function Componente(const ANome: string; AObrigatorio: Boolean = True): TComponent;
    procedure AdotarFrame;
    function ColunasDaGrade: TColunasDef;
    procedure CarregarFiltro;
    function RetangulosAcoes(const ACelula: TRect): TRetangulos;
    function ColunaAcoes(ACol: Integer): Boolean;
    function ChaveAtual: Variant;
    function DescricaoAtual: string;

    procedure GridPrepareCanvas(Sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure GridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GridCellClick(Column: TColumn);
    procedure GridDblClick(Sender: TObject);
    procedure GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EdtBuscaChange(Sender: TObject);
    procedure TmrBuscaTimer(Sender: TObject);
    procedure CmbFiltroChange(Sender: TObject);

    procedure ExecutarAcao(AIndice: Integer);
    procedure BtnNovoClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
  public
    constructor Criar(AOwner: TComponent; AParent: TWinControl; ADef: TTabelaDef;
      const AFixos: TFiltrosFixos; const ATrilha: string);
    procedure Atualizar(const AChave: Variant);
    procedure Recarregar;
    procedure Novo;
    procedure Editar;
    procedure Excluir;
    procedure FocarBusca;
    property Def: TTabelaDef read FDef;
    property OnDetalhe: TEventoDetalhe read FOnDetalhe write FOnDetalhe;
    property OnVoltar: TNotifyEvent read FOnVoltar write FOnVoltar;
  end;

implementation

uses
  uDM, uEdicao, uRelatorios;

const
  TAG_ACOES = 100;
  ALTURA_PILULA = 30;
  ESPACO_PILULA = 8;

{ TPaginaCadastro }

constructor TPaginaCadastro.Criar(AOwner: TComponent; AParent: TWinControl;
  ADef: TTabelaDef; const AFixos: TFiltrosFixos; const ATrilha: string);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FDef := ADef;
  FFixos := AFixos;
  FTrilha := ATrilha;

  Parent := AParent;
  Align := alClient;
  BevelOuter := bvNone;
  Color := corFundo;
  ParentColor := False;
  BorderSpacing.Left := 34;
  BorderSpacing.Right := 34;
  BorderSpacing.Top := 26;
  BorderSpacing.Bottom := 24;

  FSomenteLeitura := not PodeEditar;

  { botões da coluna AÇÕES: detalhes primeiro, depois Editar / Excluir
    (perfil Consulta: só "Ver") }
  if FSomenteLeitura then
    SetLength(FAcoes, Length(FDef.Detalhes) + 1)
  else
    SetLength(FAcoes, Length(FDef.Detalhes) + 2);
  for I := 0 to High(FDef.Detalhes) do
    FAcoes[I] := FDef.Detalhes[I].Rotulo;
  if FSomenteLeitura then
    FAcoes[High(FAcoes)] := 'Ver'
  else
  begin
    FAcoes[High(FAcoes) - 1] := 'Editar';
    FAcoes[High(FAcoes)] := 'Excluir';
  end;

  TmrBusca := TTimer.Create(Self);
  TmrBusca.Enabled := False;
  TmrBusca.Interval := 350;
  TmrBusca.OnTimer := @TmrBuscaTimer;

  { a tela desenhada para esta tabela }
  FFrame := ClasseLista(FDef.Tabela).Create(Self);
  FFrame.Parent := Self;
  FFrame.Align := alClient;
  AdotarFrame;
  Atualizar(Null);
end;

function TPaginaCadastro.Componente(const ANome: string; AObrigatorio: Boolean): TComponent;
begin
  Result := FFrame.FindComponent(ANome);
  if (Result = nil) and AObrigatorio then
    raise Exception.CreateFmt('A tela %s não tem o componente "%s" (não renomeie os ' +
      'componentes usados pelo sistema).', [FFrame.ClassName, ANome]);
end;

procedure TPaginaCadastro.AdotarFrame;
var
  BtnNovo, BtnImprimir, BtnVoltar: TButton;
  Cb: TComboBox;
  I, W: Integer;
begin
  QryGrid := Componente('QryLista') as TZReadOnlyQuery;
  QryGrid.Connection := DM.Conexao;
  DsGrid := Componente('DsLista') as TDataSource;
  DsGrid.DataSet := QryGrid;
  Grid := Componente('Grid') as TDBGrid;
  EdtBusca := Componente('EdtBusca') as TEdit;
  LblContagem := Componente('LblContagem') as TLabel;

  { trilha (só nas páginas de detalhe) }
  (Componente('PnlTrilha') as TControl).Visible := FTrilha <> '';
  (Componente('LblTrilha') as TLabel).Caption := FTrilha;

  { botões: eventos ligados antes de AplicarTema (o substituto copia o OnClick) }
  BtnNovo := Componente('BtnNovo') as TButton;
  BtnImprimir := Componente('BtnImprimir') as TButton;
  BtnVoltar := Componente('BtnVoltar') as TButton;
  BtnNovo.OnClick := @BtnNovoClick;
  BtnImprimir.OnClick := @BtnImprimirClick;
  BtnVoltar.OnClick := @BtnVoltarClick;
  BtnNovo.Visible := not FSomenteLeitura;

  AplicarTema(FFrame);

  { filtro opcional }
  Cb := Componente('CbFiltro', False) as TComboBox;
  if (Cb <> nil) and (FDef.FiltroCampo <> '') then
  begin
    CmbFiltro := TrocarCombo(Cb);
    CarregarFiltro;
    CmbFiltro.OnChange := @CmbFiltroChange;
  end
  else if Cb <> nil then
    Cb.Visible := False;

  EdtBusca.OnChange := @EdtBuscaChange;

  { grade }
  EstilizarGrade(Grid);
  Grid.DataSource := DsGrid;
  Grid.OnPrepareCanvas := @GridPrepareCanvas;
  Grid.OnDrawColumnCell := @GridDrawColumnCell;
  Grid.OnMouseDown := @GridMouseDown;
  Grid.OnMouseMove := @GridMouseMove;
  Grid.OnCellClick := @GridCellClick;
  Grid.OnDblClick := @GridDblClick;
  Grid.OnKeyDown := @GridKeyDown;

  { largura da coluna AÇÕES conforme os botões deste perfil }
  W := 24;
  for I := 0 to High(FAcoes) do
    Inc(W, LarguraTexto(FAcoes[I], 9) + 22 + ESPACO_PILULA);
  for I := 0 to Grid.Columns.Count - 1 do
    if Grid.Columns[I].Tag = TAG_ACOES then
    begin
      Grid.Columns[I].Width := W;
      Grid.Columns[I].SizePriority := 0;
    end;
end;

{ colunas para a impressão: as que estão na grade desenhada (sem AÇÕES) }
function TPaginaCadastro.ColunasDaGrade: TColunasDef;
var
  I, N: Integer;
  C: TColumn;
begin
  Result := nil;
  for I := 0 to Grid.Columns.Count - 1 do
  begin
    C := Grid.Columns[I];
    if (C.Tag = TAG_ACOES) or (C.FieldName = '') or not C.Visible then
      Continue;
    N := Length(Result);
    SetLength(Result, N + 1);
    Result[N].Campo := C.FieldName;
    Result[N].Titulo := C.Title.Caption;
    Result[N].Largura := C.Width;
    if (C.Tag >= Ord(Low(TEstiloColuna))) and (C.Tag <= Ord(High(TEstiloColuna))) then
      Result[N].Estilo := TEstiloColuna(C.Tag)
    else
      Result[N].Estilo := ecNormal;
  end;
end;

procedure TPaginaCadastro.CarregarFiltro;
var
  Q: TZReadOnlyQuery;
begin
  CmbFiltro.Limpar;
  CmbFiltro.Adicionar(FDef.FiltroTodos, Null);
  Q := DM.NovaConsulta(nil, FDef.FiltroSQL);
  try
    Q.Open;
    while not Q.EOF do
    begin
      CmbFiltro.Adicionar(Q.FieldByName('descricao').AsString, Q.FieldByName('codigo').Value);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  CmbFiltro.ItemIndex := 0;
end;

{ ------------------------------ dados ------------------------------ }

procedure TPaginaCadastro.Atualizar(const AChave: Variant);
var
  S, Where, Busca: string;
  I: Integer;
  UsaFiltro: Boolean;
begin
  Where := '';
  for I := 0 to High(FFixos) do
    Where := Where + StrUtils.IfThen(Where <> '', ' AND ', '') +
      Format('%s.%s = :f%d', [FDef.Alias, FFixos[I].Campo, I]);

  Busca := Trim(EdtBusca.Text);
  if Busca <> '' then
    Where := Where + StrUtils.IfThen(Where <> '', ' AND ', '') + FDef.CampoBusca + ' LIKE :busca';

  UsaFiltro := (CmbFiltro <> nil) and (CmbFiltro.ItemIndex > 0);
  if UsaFiltro then
    Where := Where + StrUtils.IfThen(Where <> '', ' AND ', '') + FDef.FiltroCampo + ' = :filtro';

  S := FDef.SQLGrid;
  if Where <> '' then
    S := S + ' WHERE ' + Where;
  if FDef.Ordem <> '' then
    S := S + ' ORDER BY ' + FDef.Ordem;

  Screen.Cursor := crHourGlass;
  QryGrid.DisableControls;
  try
    QryGrid.Close;
    QryGrid.SQL.Text := S;
    for I := 0 to High(FFixos) do
      QryGrid.ParamByName('f' + IntToStr(I)).Value := FFixos[I].Valor;
    if Busca <> '' then
      QryGrid.ParamByName('busca').AsString := '%' + Busca + '%';
    if UsaFiltro then
      QryGrid.ParamByName('filtro').Value := CmbFiltro.Valor;
    QryGrid.Open;
    for I := 0 to QryGrid.FieldCount - 1 do
      if QryGrid.Fields[I] is TDateTimeField then
      begin
        { colunas de "acesso" (data e hora); demais só a data }
        if Pos('acesso', QryGrid.Fields[I].FieldName) > 0 then
          TDateTimeField(QryGrid.Fields[I]).DisplayFormat := 'dd/mm/yyyy hh:nn'
        else
          TDateTimeField(QryGrid.Fields[I]).DisplayFormat := 'dd/mm/yyyy';
      end;
    if not VarIsNull(AChave) then
      QryGrid.Locate(FDef.Chave, AChave, []);
  finally
    QryGrid.EnableControls;
    Screen.Cursor := crDefault;
  end;

  case QryGrid.RecordCount of
    0: LblContagem.Caption := 'Nenhum registro encontrado';
    1: LblContagem.Caption := '1 registro  ·  duplo clique para editar';
  else
    LblContagem.Caption := Format('%d registros  ·  duplo clique para editar',
      [QryGrid.RecordCount]);
  end;
end;

procedure TPaginaCadastro.Recarregar;
begin
  Atualizar(ChaveAtual);
end;

function TPaginaCadastro.ChaveAtual: Variant;
begin
  if QryGrid.Active and not QryGrid.IsEmpty then
    Result := QryGrid.FieldByName(FDef.Chave).Value
  else
    Result := Null;
end;

function TPaginaCadastro.DescricaoAtual: string;
var
  F: TField;
begin
  Result := '';
  if QryGrid.IsEmpty then
    Exit;
  F := QryGrid.FindField(FDef.CampoDescricao);
  if F <> nil then
    Result := F.AsString;
end;

{ ------------------------------ ações ------------------------------ }

procedure TPaginaCadastro.Novo;
var
  Chave: Variant;
  Ok: Boolean;
begin
  if FSomenteLeitura then
    Exit;
  if Assigned(FDef.Editor) then
    Ok := FDef.Editor(FDef, Null, FFixos, FTrilha, Chave)
  else
    Ok := EditarRegistro(FDef, Null, FFixos, FTrilha, Chave);
  if Ok then
    Atualizar(Chave);
end;

{ No perfil Consulta abre o mesmo diálogo, só para leitura }
procedure TPaginaCadastro.Editar;
var
  Chave: Variant;
  Ok: Boolean;
begin
  if VarIsNull(ChaveAtual) then
    Exit;
  try
    if Assigned(FDef.Editor) and not FSomenteLeitura then
      Ok := FDef.Editor(FDef, ChaveAtual, FFixos, FTrilha, Chave)
    else
      Ok := EditarRegistro(FDef, ChaveAtual, FFixos, FTrilha, Chave, FSomenteLeitura);
    if Ok then
      Atualizar(Chave);
  except
    on E: Exception do
    begin
      Avisar('Não foi possível editar', E.Message);
      Recarregar;
    end;
  end;
end;

procedure TPaginaCadastro.Excluir;
var
  Chave: Variant;
  Desc, Motivo: string;
begin
  Chave := ChaveAtual;
  if FSomenteLeitura or VarIsNull(Chave) then
    Exit;
  Desc := DescricaoAtual;
  if Assigned(FDef.ValidarExclusao) then
  begin
    Motivo := FDef.ValidarExclusao(Chave);
    if Motivo <> '' then
    begin
      Avisar('Não é possível excluir', Motivo);
      Exit;
    end;
  end;
  if not Confirmar('Excluir ' + FDef.NomeSingular,
    Format('Deseja excluir "%s"? Esta ação não pode ser desfeita.', [Desc]),
    'Excluir', True) then
    Exit;
  try
    DM.ExecutarSQL(Format('DELETE FROM %s WHERE %s = :p0', [FDef.Tabela, FDef.Chave]), [Chave]);
  except
    on E: Exception do
    begin
      Avisar('Não foi possível excluir',
        'O registro está sendo usado em outro cadastro. Exclua primeiro os ' +
        'registros dependentes.' + LineEnding + LineEnding + E.Message);
      Exit;
    end;
  end;
  Atualizar(Null);
end;

procedure TPaginaCadastro.ExecutarAcao(AIndice: Integer);
var
  D: TDetalheDef;
  Fixos: TFiltrosFixos;
  Q: TZReadOnlyQuery;
  I: Integer;
  Trilha: string;
begin
  if AIndice > High(FDef.Detalhes) then
  begin
    if FAcoes[AIndice] = 'Excluir' then
      Excluir
    else
      Editar;   // "Editar" ou "Ver"
  end
  else if Assigned(FOnDetalhe) and not VarIsNull(ChaveAtual) then
  begin
    D := FDef.Detalhes[AIndice];
    { os campos de ligação podem não estar no SELECT do grid: lê o registro }
    Q := DM.NovaConsulta(nil, Format('SELECT * FROM %s WHERE %s = :k', [FDef.Tabela, FDef.Chave]));
    try
      Q.ParamByName('k').Value := ChaveAtual;
      Q.Open;
      SetLength(Fixos, Length(D.Ligacoes));
      for I := 0 to High(D.Ligacoes) do
      begin
        Fixos[I].Campo := D.Ligacoes[I].CampoDetalhe;
        Fixos[I].Valor := Q.FieldByName(D.Ligacoes[I].CampoMestre).Value;
      end;
    finally
      Q.Free;
    end;
    Trilha := FTrilha + StrUtils.IfThen(FTrilha <> '', '  ›  ', '') +
      FDef.RotuloRegistro + ' ' + DescricaoAtual;
    FOnDetalhe(D.Tabela, Fixos, Trilha);
  end;
end;

procedure TPaginaCadastro.BtnNovoClick(Sender: TObject);
begin
  Novo;
end;

procedure TPaginaCadastro.BtnImprimirClick(Sender: TObject);
var
  Chave: Variant;
begin
  if QryGrid.IsEmpty then
  begin
    Avisar('Imprimir', 'Não há registros para imprimir.');
    Exit;
  end;
  Chave := ChaveAtual;
  QryGrid.DisableControls;
  try
    ImprimirListagem(FDef.Titulo, FTrilha, QryGrid, ColunasDaGrade);
  finally
    QryGrid.Locate(FDef.Chave, Chave, []);
    QryGrid.EnableControls;
  end;
end;

procedure TPaginaCadastro.BtnVoltarClick(Sender: TObject);
begin
  if Assigned(FOnVoltar) then
    FOnVoltar(Self);
end;

procedure TPaginaCadastro.FocarBusca;
begin
  if EdtBusca.CanFocus then
    EdtBusca.SetFocus;
end;

{ ------------------------------ eventos ----------------------------- }

procedure TPaginaCadastro.EdtBuscaChange(Sender: TObject);
begin
  { pesquisa enquanto digita, com pequeno atraso }
  TmrBusca.Enabled := False;
  TmrBusca.Enabled := True;
end;

procedure TPaginaCadastro.TmrBuscaTimer(Sender: TObject);
begin
  TmrBusca.Enabled := False;
  Atualizar(Null);
end;

procedure TPaginaCadastro.CmbFiltroChange(Sender: TObject);
begin
  Atualizar(Null);
end;

function TPaginaCadastro.RetangulosAcoes(const ACelula: TRect): TRetangulos;
var
  I, X, Y, W: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FAcoes));
  X := ACelula.Left + 12;
  Y := ACelula.Top + (ACelula.Bottom - ACelula.Top - ALTURA_PILULA) div 2;
  for I := 0 to High(FAcoes) do
  begin
    W := LarguraTexto(FAcoes[I], 9) + 22;
    Result[I] := Rect(X, Y, X + W, Y + ALTURA_PILULA);
    Inc(X, W + ESPACO_PILULA);
  end;
end;

function TPaginaCadastro.ColunaAcoes(ACol: Integer): Boolean;
begin
  { a grade não tem indicador: coluna visual = índice da coluna }
  Result := (ACol >= 0) and (ACol < Grid.Columns.Count) and
    (Grid.Columns[ACol].Tag = TAG_ACOES);
end;

procedure TPaginaCadastro.GridPrepareCanvas(Sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
begin
  if gdFixed in AState then
  begin
    Grid.Canvas.Brush.Color := corCartao;
    Grid.Canvas.Font.Color := corTextoSuave;
    Grid.Canvas.Font.Style := [fsBold];
    Grid.Canvas.Font.Size := 8;
  end
  else
  begin
    if gdSelected in AState then
      Grid.Canvas.Brush.Color := corSelecao
    else
      Grid.Canvas.Brush.Color := corCartao;
    Grid.Canvas.Font.Color := corTexto;
  end;
end;

procedure TPaginaCadastro.GridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  C: TCanvas;
  Fundo: TColor;
  R: TRect;
  TS: TTextStyle;
  Pilulas: TRetangulos;
  I: Integer;
  Estilo: TEstiloBotao;
begin
  C := Grid.Canvas;
  if gdSelected in State then
    Fundo := corSelecao
  else
    Fundo := corCartao;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Fundo;
  C.FillRect(Rect);

  if QryGrid.IsEmpty then
    Exit;

  C.Font.Size := 10;
  if Column.Tag = TAG_ACOES then
  begin
    C.Font.Size := 9;
    Pilulas := RetangulosAcoes(Rect);
    for I := 0 to High(Pilulas) do
    begin
      if FAcoes[I] = 'Excluir' then
        Estilo := ebPerigo
      else
        Estilo := ebSecundario;
      DesenharPilula(C, Pilulas[I], FAcoes[I], Estilo, Fundo);
    end;
    Exit;
  end;

  if (Column.Tag < Ord(Low(TEstiloColuna))) or (Column.Tag > Ord(High(TEstiloColuna))) then
    Column.Tag := Ord(ecNormal);
  case TEstiloColuna(Column.Tag) of
    ecDestaque:
      begin
        C.Font.Color := clWhite;
        C.Font.Style := [fsBold];
      end;
    ecNumero:
      begin
        C.Font.Color := corNumero;
        C.Font.Style := [fsBold];
      end;
    ecSuave:
      begin
        C.Font.Color := corTextoSuave;
        C.Font.Style := [];
      end;
  else
    begin
      C.Font.Color := corTexto;
      C.Font.Style := [];
    end;
  end;

  if Column.Field = nil then
    Exit;
  R := Classes.Rect(Rect.Left + 12, Rect.Top, Rect.Right - 6, Rect.Bottom);
  TS := C.TextStyle;
  TS.Alignment := taLeftJustify;
  TS.Layout := tlCenter;
  TS.SingleLine := True;
  TS.Clipping := True;
  TS.EndEllipsis := True;
  TS.Opaque := False;
  C.Brush.Style := bsClear;
  C.TextRect(R, R.Left, R.Top, Column.Field.DisplayText, TS);
end;

procedure TPaginaCadastro.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMouseX := X;
  FMouseY := Y;
end;

procedure TPaginaCadastro.GridMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  ACol, ARow, I: Integer;
  Pilulas: TRetangulos;
  Sobre: Boolean;
begin
  Sobre := False;
  Grid.MouseToCell(X, Y, ACol, ARow);
  if (ARow >= 1) and ColunaAcoes(ACol) and not QryGrid.IsEmpty then
  begin
    Pilulas := RetangulosAcoes(Grid.CellRect(ACol, ARow));
    for I := 0 to High(Pilulas) do
      if PtInRect(Pilulas[I], Point(X, Y)) then
        Sobre := True;
  end;
  if Sobre then
    Grid.Cursor := crHandPoint
  else
    Grid.Cursor := crDefault;
end;

procedure TPaginaCadastro.GridCellClick(Column: TColumn);
var
  ACol, ARow, I: Integer;
  Pilulas: TRetangulos;
begin
  if (Column = nil) or (Column.Tag <> TAG_ACOES) or QryGrid.IsEmpty then
    Exit;
  Grid.MouseToCell(FMouseX, FMouseY, ACol, ARow);
  if (ARow < 1) or not ColunaAcoes(ACol) then
    Exit;
  Pilulas := RetangulosAcoes(Grid.CellRect(ACol, ARow));
  for I := 0 to High(Pilulas) do
    if PtInRect(Pilulas[I], Point(FMouseX, FMouseY)) then
    begin
      ExecutarAcao(I);
      Exit;
    end;
end;

procedure TPaginaCadastro.GridDblClick(Sender: TObject);
var
  ACol, ARow: Integer;
begin
  Grid.MouseToCell(FMouseX, FMouseY, ACol, ARow);
  if (ARow >= 1) and not ColunaAcoes(ACol) then
    Editar;
end;

procedure TPaginaCadastro.GridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        Editar;
      end;
    VK_DELETE:
      begin
        Key := 0;
        Excluir;
      end;
  end;
end;

end.
