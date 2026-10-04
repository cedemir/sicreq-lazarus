unit uEscolha;

{ TCaixaEscolha - "combo" escuro desenhado pelo programa.

  Substitui TComboBox / TDBLookupComboBox para que a caixa fechada, a seta
  e a lista aberta sigam o tema em qualquer plataforma (no GTK2 e no
  Windows o combo nativo ignora parte das cores).

  - Itens: texto + valor (Variant).
  - Opcionalmente ligado a um campo (DataSource/DataField), como os
    controles DB da LCL: mostra o valor do campo e grava o valor escolhido.
  - A lista aberta NÃO é uma janela: é um painel colocado à frente, dentro
    do próprio formulário. Assim funciona igual em diálogos modais (no GTK
    uma janela aberta sobre um diálogo modal não recebe cliques). Clique
    fora fecha a lista. Com muitos itens ganha um campo de pesquisa.
  - Teclado: setas, Home/End, letras (pula para o item), Enter/Espaço/F4
    ou Alt+seta abrem a lista, Esc fecha. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Variants, Math, Controls, Graphics, Forms,
  StdCtrls, ExtCtrls, LCLType, LCLIntf, LMessages, LazUTF8, DB, DBCtrls, uTema;

const
  { a partir de quantos itens a lista aberta mostra o campo de pesquisa }
  ITENS_PARA_PESQUISA = 12;

type
  TCaixaEscolha = class;

  { TListaEscolha - lista aberta (painel dentro do formulário) }

  TListaEscolha = class(TCustomControl)
  private
    FDono: TCaixaEscolha;
    FPesquisa: TEdit;
    FLista: TListBox;
    FMapa: array of Integer;   // linha da lista -> índice do item no dono
    FFechando: Boolean;
    procedure Filtrar;
    procedure Escolher;
    procedure ListaDesenhar(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ListaClick(Sender: TObject);
    procedure ListaMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ListaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PesquisaChange(Sender: TObject);
    procedure PesquisaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EntradaUsuario(Sender: TObject; Msg: Cardinal);
    function ContemPontoTela(AControle: TControl; const P: TPoint): Boolean;
  protected
    procedure Paint; override;
  public
    constructor Criar(ADono: TCaixaEscolha);
    destructor Destroy; override;
    procedure Abrir;
    procedure Fechar;
  end;

  { TCaixaEscolha }

  TCaixaEscolha = class(TCustomControl)
  private
    FTextos: TStringList;
    FValores: array of Variant;
    FItemIndex: Integer;
    FTextoVazio: string;
    FReadOnly: Boolean;
    FHover: Boolean;
    FPopup: TListaEscolha;
    FBusca: string;
    FBuscaEm: QWord;
    FDataLink: TFieldDataLink;
    FOnChange: TNotifyEvent;
    FCorFundo: TColor;
    function GetCount: Integer;
    function GetValor: Variant;
    procedure SetValor(const AValue: Variant);
    procedure SetItemIndex(AValue: Integer);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(AValue: TDataSource);
    procedure DataChange(Sender: TObject);
    procedure Selecionar(AIndice: Integer);
    function IndiceDoValor(const AValor: Variant): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure UTF8KeyPress(var UTF8Key: TUTF8Char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Limpar;
    procedure Adicionar(const ATexto: string; const AValor: Variant);
    { Carrega os itens de um dataset com as colunas "codigo" e "descricao" }
    procedure CarregarDe(ADataSet: TDataSet);
    procedure AbrirLista;
    procedure FecharLista;
    function Texto(AIndice: Integer): string;
    property Count: Integer read GetCount;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property Valor: Variant read GetValor write SetValor;
    property TextoVazio: string read FTextoVazio write FTextoVazio;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property CorFundo: TColor read FCorFundo write FCorFundo;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

{ True enquanto alguma lista de escolha está aberta. Os formulários que
  tratam Esc/Enter em KeyPreview devem consultar isto antes. }
function EscolhaAberta: Boolean;

implementation

var
  FListaAberta: TListaEscolha = nil;

function EscolhaAberta: Boolean;
begin
  Result := FListaAberta <> nil;
end;

const
  ALTURA_ITEM = 30;
  MAX_LINHAS = 10;

{ ------------------------------------------------------------------ }
{ TListaEscolha                                                       }
{ ------------------------------------------------------------------ }

constructor TListaEscolha.Criar(ADono: TCaixaEscolha);
var
  Form: TCustomForm;
begin
  inherited Create(nil);
  FDono := ADono;
  Form := GetParentForm(ADono);
  Parent := Form;
  ControlStyle := ControlStyle + [csAcceptsControls];

  if FDono.Count >= ITENS_PARA_PESQUISA then
  begin
    FPesquisa := TEdit.Create(Self);
    FPesquisa.Parent := Self;
    FPesquisa.Align := alTop;
    FPesquisa.BorderSpacing.Around := 8;
    FPesquisa.TextHint := 'Pesquisar...';
    EstilizarEntrada(FPesquisa);
    FPesquisa.BorderStyle := bsSingle;
    FPesquisa.OnChange := @PesquisaChange;
    FPesquisa.OnKeyDown := @PesquisaKeyDown;
  end;

  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := alClient;
  FLista.BorderSpacing.Around := 2;
  FLista.BorderStyle := bsNone;
  FLista.Style := lbOwnerDrawFixed;
  FLista.ItemHeight := ALTURA_ITEM;
  FLista.Color := corEntrada;
  FLista.Font.Color := corTexto;
  FLista.Font.Size := 10;
  FLista.ClickOnSelChange := False;   // OnClick só no clique do mouse
  FLista.OnDrawItem := @ListaDesenhar;
  FLista.OnClick := @ListaClick;
  FLista.OnMouseUp := @ListaMouseUp;
  FLista.OnMouseMove := @ListaMouseMove;
  FLista.OnKeyDown := @ListaKeyDown;

  { clique em qualquer lugar fora da lista fecha a lista }
  Application.AddOnUserInputHandler(@EntradaUsuario, False);
  FListaAberta := Self;
end;

destructor TListaEscolha.Destroy;
begin
  Application.RemoveOnUserInputHandler(@EntradaUsuario);
  if FListaAberta = Self then
    FListaAberta := nil;
  inherited Destroy;
end;

procedure TListaEscolha.Paint;
begin
  { fundo da lista com borda de 1 px }
  Canvas.Brush.Color := corEntrada;
  Canvas.Pen.Color := corBordaForte;
  Canvas.Rectangle(ClientRect);
end;

procedure TListaEscolha.Filtrar;
var
  I, N, Atual: Integer;
  Termo: string;
begin
  if FPesquisa <> nil then
    Termo := UTF8LowerCase(Trim(FPesquisa.Text))
  else
    Termo := '';
  FLista.Items.BeginUpdate;
  try
    FLista.Items.Clear;
    SetLength(FMapa, 0);
    Atual := -1;
    for I := 0 to FDono.Count - 1 do
      if (Termo = '') or (Pos(Termo, UTF8LowerCase(FDono.Texto(I))) > 0) then
      begin
        N := Length(FMapa);
        SetLength(FMapa, N + 1);
        FMapa[N] := I;
        FLista.Items.Add(FDono.Texto(I));
        if I = FDono.ItemIndex then
          Atual := N;
      end;
  finally
    FLista.Items.EndUpdate;
  end;
  if Atual >= 0 then
    FLista.ItemIndex := Atual
  else if FLista.Count > 0 then
    FLista.ItemIndex := 0;
end;

procedure TListaEscolha.Abrir;
var
  Form: TCustomForm;
  P: TPoint;
  Alt, Larg, Espaco: Integer;
begin
  Filtrar;
  Form := GetParentForm(FDono);
  Alt := Min(Max(FLista.Count, 1), MAX_LINHAS) * ALTURA_ITEM + 8;
  if FPesquisa <> nil then
    Inc(Alt, FPesquisa.Height + 16);
  Larg := Max(FDono.Width, 220);

  { posição da caixa em coordenadas do formulário }
  P := Form.ScreenToClient(FDono.ClientToScreen(Point(0, 0)));
  Espaco := Form.ClientHeight - (P.Y + FDono.Height + 4);
  if (Alt > Espaco) and (P.Y - 4 > Espaco) then
  begin
    { mais espaço em cima: abre para cima }
    Alt := Min(Alt, P.Y - 8);
    P.Y := P.Y - Alt - 4;
  end
  else
  begin
    Alt := Min(Alt, Max(Espaco - 4, ALTURA_ITEM * 3));
    P.Y := P.Y + FDono.Height + 4;
  end;
  if P.X + Larg > Form.ClientWidth then
    P.X := Max(0, Form.ClientWidth - Larg);
  SetBounds(P.X, P.Y, Larg, Alt);

  BringToFront;
  Visible := True;
  if (FPesquisa <> nil) and FPesquisa.CanFocus then
    FPesquisa.SetFocus
  else if FLista.CanFocus then
    FLista.SetFocus;
  if FLista.ItemIndex >= 0 then
    FLista.MakeCurrentVisible;
end;

procedure TListaEscolha.Escolher;
var
  I: Integer;
begin
  if FFechando then
    Exit;
  I := FLista.ItemIndex;
  if (I >= 0) and (I <= High(FMapa)) then
    FDono.Selecionar(FMapa[I]);
  Fechar;
end;

procedure TListaEscolha.Fechar;
begin
  if FFechando then
    Exit;
  FFechando := True;
  Visible := False;
  if FListaAberta = Self then
    FListaAberta := nil;
  if FDono <> nil then
  begin
    FDono.FPopup := nil;
    FDono.Invalidate;
    if FDono.CanFocus then
      FDono.SetFocus;
  end;
  { pode estar dentro de um evento da própria lista: libera depois }
  Application.ReleaseComponent(Self);
end;

function TListaEscolha.ContemPontoTela(AControle: TControl; const P: TPoint): Boolean;
var
  A: TPoint;
begin
  A := AControle.ClientToScreen(Point(0, 0));
  Result := (P.X >= A.X) and (P.X < A.X + AControle.Width) and
            (P.Y >= A.Y) and (P.Y < A.Y + AControle.Height);
end;

procedure TListaEscolha.EntradaUsuario(Sender: TObject; Msg: Cardinal);
var
  P: TPoint;
begin
  if FFechando or not Visible then
    Exit;
  if (Msg = LM_LBUTTONDOWN) or (Msg = LM_RBUTTONDOWN) or (Msg = LM_MBUTTONDOWN) or
     (Msg = LM_NCLBUTTONDOWN) then
  begin
    P := Mouse.CursorPos;
    { clique na própria caixa: ela mesma trata (abre/fecha) }
    if not ContemPontoTela(Self, P) and not ContemPontoTela(FDono, P) then
      Fechar;
  end;
end;

procedure TListaEscolha.ListaDesenhar(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  R: TRect;
  TS: TTextStyle;
  Marcado: Boolean;
begin
  C := FLista.Canvas;
  Marcado := (Index <= High(FMapa)) and (FMapa[Index] = FDono.ItemIndex);
  if odSelected in State then
    C.Brush.Color := corSelecao
  else
    C.Brush.Color := corEntrada;
  C.Brush.Style := bsSolid;
  C.FillRect(ARect);

  if Marcado then
  begin
    { barra azul à esquerda no item atualmente escolhido }
    C.Brush.Color := corPrimaria;
    C.FillRect(Rect(ARect.Left, ARect.Top + 6, ARect.Left + 3, ARect.Bottom - 6));
  end;

  C.Font.Size := 10;
  if (odSelected in State) or Marcado then
  begin
    C.Font.Color := clWhite;
    C.Font.Style := [fsBold];
  end
  else
  begin
    C.Font.Color := corTexto;
    C.Font.Style := [];
  end;
  R := Rect(ARect.Left + 14, ARect.Top, ARect.Right - 6, ARect.Bottom);
  TS := C.TextStyle;
  TS.Alignment := taLeftJustify;
  TS.Layout := tlCenter;
  TS.SingleLine := True;
  TS.Clipping := True;
  TS.EndEllipsis := True;
  TS.Opaque := False;
  C.Brush.Style := bsClear;
  C.TextRect(R, R.Left, R.Top, FLista.Items[Index], TS);
end;

procedure TListaEscolha.ListaClick(Sender: TObject);
begin
  Escolher;
end;

procedure TListaEscolha.ListaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  if Button <> mbLeft then
    Exit;
  I := FLista.GetIndexAtXY(X, Y);
  if I < 0 then
    Exit;
  FLista.ItemIndex := I;
  Escolher;
end;

{ o item sob o ponteiro fica destacado (só destaca; escolher é no clique) }
procedure TListaEscolha.ListaMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  I: Integer;
begin
  I := FLista.GetIndexAtXY(X, Y);
  if (I >= 0) and (I <> FLista.ItemIndex) then
    FLista.ItemIndex := I;
end;

procedure TListaEscolha.ListaKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN, VK_SPACE:
      begin
        Key := 0;
        Escolher;
      end;
    VK_ESCAPE, VK_TAB:
      begin
        Key := 0;
        Fechar;
      end;
    VK_UP:
      if (FLista.ItemIndex <= 0) and (FPesquisa <> nil) then
      begin
        Key := 0;
        FPesquisa.SetFocus;
      end;
  end;
end;

procedure TListaEscolha.PesquisaChange(Sender: TObject);
begin
  Filtrar;
end;

procedure TListaEscolha.PesquisaKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_DOWN:
      begin
        Key := 0;
        FLista.SetFocus;
      end;
    VK_RETURN:
      begin
        Key := 0;
        Escolher;
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        Fechar;
      end;
  end;
end;

{ ------------------------------------------------------------------ }
{ TCaixaEscolha                                                       }
{ ------------------------------------------------------------------ }

constructor TCaixaEscolha.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextos := TStringList.Create;
  FItemIndex := -1;
  FTextoVazio := 'Selecione...';
  FCorFundo := corCartao;
  TabStop := True;
  Cursor := crHandPoint;
  Height := 42;
  Width := 220;
  Font.Size := 10;
  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := @DataChange;
end;

destructor TCaixaEscolha.Destroy;
begin
  if FPopup <> nil then
  begin
    FPopup.FDono := nil;
    FPopup.Fechar;
    FPopup := nil;
  end;
  FDataLink.Free;
  FTextos.Free;
  inherited Destroy;
end;

procedure TCaixaEscolha.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TCaixaEscolha.Limpar;
begin
  FTextos.Clear;
  SetLength(FValores, 0);
  FItemIndex := -1;
  Invalidate;
end;

procedure TCaixaEscolha.Adicionar(const ATexto: string; const AValor: Variant);
var
  N: Integer;
begin
  FTextos.Add(ATexto);
  N := Length(FValores);
  SetLength(FValores, N + 1);
  FValores[N] := AValor;
end;

procedure TCaixaEscolha.CarregarDe(ADataSet: TDataSet);
begin
  Limpar;
  ADataSet.First;
  while not ADataSet.EOF do
  begin
    Adicionar(ADataSet.FieldByName('descricao').AsString,
      ADataSet.FieldByName('codigo').Value);
    ADataSet.Next;
  end;
  DataChange(nil);
end;

function TCaixaEscolha.Texto(AIndice: Integer): string;
begin
  Result := FTextos[AIndice];
end;

function TCaixaEscolha.GetCount: Integer;
begin
  Result := FTextos.Count;
end;

function TCaixaEscolha.GetValor: Variant;
begin
  if (FItemIndex >= 0) and (FItemIndex <= High(FValores)) then
    Result := FValores[FItemIndex]
  else
    Result := Null;
end;

function TCaixaEscolha.IndiceDoValor(const AValor: Variant): Integer;
var
  I: Integer;
begin
  Result := -1;
  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    Exit;
  for I := 0 to High(FValores) do
    if not VarIsNull(FValores[I]) and (VarToStr(FValores[I]) = VarToStr(AValor)) then
      Exit(I);
end;

procedure TCaixaEscolha.SetValor(const AValue: Variant);
begin
  SetItemIndex(IndiceDoValor(AValue));
end;

procedure TCaixaEscolha.SetItemIndex(AValue: Integer);
begin
  if (AValue < -1) or (AValue >= Count) then
    AValue := -1;
  if FItemIndex = AValue then
    Exit;
  FItemIndex := AValue;
  Invalidate;
end;

{ escolha feita pelo usuário (lista, teclado) }
procedure TCaixaEscolha.Selecionar(AIndice: Integer);
begin
  if FReadOnly or (AIndice < 0) or (AIndice >= Count) or (AIndice = FItemIndex) then
    Exit;
  if FDataLink.Field <> nil then
  begin
    if not FDataLink.Edit then
      Exit;
    FDataLink.Field.Value := FValores[AIndice];   // DataChange atualiza a tela
  end;
  FItemIndex := AIndice;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ ---------- ligação com o banco ---------- }

function TCaixaEscolha.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

function TCaixaEscolha.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TCaixaEscolha.SetDataField(const AValue: string);
begin
  FDataLink.FieldName := AValue;
end;

procedure TCaixaEscolha.SetDataSource(AValue: TDataSource);
begin
  FDataLink.DataSource := AValue;
  if AValue <> nil then
    AValue.FreeNotification(Self);
end;

procedure TCaixaEscolha.DataChange(Sender: TObject);
begin
  if FDataLink.Field = nil then
    Exit;
  SetItemIndex(IndiceDoValor(FDataLink.Field.Value));
end;

{ ---------- desenho ---------- }

procedure TCaixaEscolha.Paint;
var
  R, RT: TRect;
  Borda: TColor;
  TS: TTextStyle;
  CX, CY: Integer;
  Txt: string;
begin
  R := ClientRect;
  if Focused or (FPopup <> nil) then
    Borda := corPrimaria
  else if FHover and not FReadOnly then
    Borda := corTextoSuave
  else
    Borda := corBordaForte;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FCorFundo;
  Canvas.FillRect(R);
  if FReadOnly then
    Canvas.Brush.Color := corCartao
  else
    Canvas.Brush.Color := corEntrada;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := Borda;
  Canvas.Pen.Width := 1;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 16, 16);

  { texto }
  Canvas.Font.Assign(Font);
  if FItemIndex >= 0 then
  begin
    Txt := FTextos[FItemIndex];
    if FReadOnly then
      Canvas.Font.Color := corTextoSuave
    else
      Canvas.Font.Color := corTexto;
  end
  else
  begin
    Txt := FTextoVazio;
    Canvas.Font.Color := corTextoSuave;
  end;
  RT := Rect(R.Left + 14, R.Top, R.Right - 34, R.Bottom);
  TS := Canvas.TextStyle;
  TS.Alignment := taLeftJustify;
  TS.Layout := tlCenter;
  TS.SingleLine := True;
  TS.Clipping := True;
  TS.EndEllipsis := True;
  TS.Opaque := False;
  Canvas.Brush.Style := bsClear;
  Canvas.TextRect(RT, RT.Left, RT.Top, Txt, TS);

  { seta (chevron) }
  if not FReadOnly then
  begin
    CX := R.Right - 18;
    CY := (R.Top + R.Bottom) div 2;
    Canvas.Pen.Color := corTextoSuave;
    Canvas.Pen.Width := 2;
    if FPopup <> nil then
      Canvas.Polyline([Point(CX - 5, CY + 2), Point(CX, CY - 3), Point(CX + 5, CY + 2)])
    else
      Canvas.Polyline([Point(CX - 5, CY - 2), Point(CX, CY + 3), Point(CX + 5, CY - 2)]);
    Canvas.Pen.Width := 1;
  end;
end;

{ ---------- interação ---------- }

procedure TCaixaEscolha.AbrirLista;
begin
  if FReadOnly or (FPopup <> nil) or (Count = 0) then
    Exit;
  FPopup := TListaEscolha.Criar(Self);
  Invalidate;
  FPopup.Abrir;
end;

procedure TCaixaEscolha.FecharLista;
begin
  if FPopup <> nil then
    FPopup.Fechar;
end;

procedure TCaixaEscolha.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus then
    SetFocus;
  if Button <> mbLeft then
    Exit;
  { clique na caixa alterna: abre ou fecha a lista }
  if FPopup <> nil then
    FecharLista
  else
    AbrirLista;
end;

procedure TCaixaEscolha.MouseEnter;
begin
  inherited MouseEnter;
  FHover := True;
  Invalidate;
end;

procedure TCaixaEscolha.MouseLeave;
begin
  inherited MouseLeave;
  FHover := False;
  Invalidate;
end;

procedure TCaixaEscolha.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TCaixaEscolha.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TCaixaEscolha.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if FReadOnly then
    Exit;
  case Key of
    VK_RETURN, VK_SPACE, VK_F4:
      begin
        Key := 0;
        AbrirLista;
      end;
    VK_DOWN:
      begin
        Key := 0;
        if ssAlt in Shift then
          AbrirLista
        else
          Selecionar(Min(FItemIndex + 1, Count - 1));
      end;
    VK_UP:
      begin
        Key := 0;
        if ssAlt in Shift then
          AbrirLista
        else if FItemIndex > 0 then
          Selecionar(FItemIndex - 1);
      end;
    VK_HOME:
      begin
        Key := 0;
        Selecionar(0);
      end;
    VK_END:
      begin
        Key := 0;
        Selecionar(Count - 1);
      end;
  end;
end;

{ Roda do mouse sobre a caixa fechada: para baixo = próximo item,
  para cima = item anterior (como o combo nativo) }
function TCaixaEscolha.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if FReadOnly or (Count = 0) or (FPopup <> nil) then
    Exit(inherited DoMouseWheel(Shift, WheelDelta, MousePos));
  if WheelDelta < 0 then
    Selecionar(Min(FItemIndex + 1, Count - 1))
  else if FItemIndex > 0 then
    Selecionar(FItemIndex - 1)
  else if FItemIndex < 0 then
    Selecionar(0);
  Result := True;   // consumido: não rola o formulário
end;

procedure TCaixaEscolha.UTF8KeyPress(var UTF8Key: TUTF8Char);
var
  I, Inicio: Integer;
begin
  inherited UTF8KeyPress(UTF8Key);
  if FReadOnly or (UTF8Key = '') or (UTF8Key[1] < ' ') then
    Exit;
  { digitação rápida acumula ("SUP" -> SUPERMAN); pausa recomeça }
  if GetTickCount64 - FBuscaEm > 900 then
    FBusca := '';
  FBuscaEm := GetTickCount64;
  FBusca := FBusca + UTF8LowerCase(UTF8Key);
  Inicio := Max(FItemIndex, 0);
  if UTF8Length(FBusca) = 1 then
    Inc(Inicio);       // mesma letra de novo: vai para o próximo
  for I := 0 to Count - 1 do
    if Pos(FBusca, UTF8LowerCase(FTextos[(Inicio + I) mod Count])) = 1 then
    begin
      Selecionar((Inicio + I) mod Count);
      Break;
    end;
  UTF8Key := '';
end;

end.
