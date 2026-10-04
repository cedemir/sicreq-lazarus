unit uTema;

{ Tema escuro do SICREQ e controles visuais próprios.

  Os botões nativos não aceitam cor de fundo no GTK2 nem no Windows, por
  isso o visual (botões, cartões arredondados, caixas de texto) é pintado
  aqui, sobre TCustomControl. Nenhum componente de terceiros é necessário. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Controls, Graphics, Forms, StdCtrls, ExtCtrls,
  DBGrids, Grids, LCLType;

var
  { Paleta (preenchida em initialization) }
  corFundo,          // fundo das páginas
  corLateral,        // menu lateral
  corCartao,         // cartões / tabela
  corEntrada,        // caixas de texto
  corBorda,          // bordas e linhas
  corBordaForte,     // borda de botões secundários
  corSelecao,        // linha selecionada / item de menu ativo
  corHover,          // passagem do mouse
  corPrimaria,       // azul
  corPrimariaHover,
  corTexto,          // texto principal
  corTextoSuave,     // rótulos, descrições
  corTextoMenu,
  corDestaque,       // eyebrow (azul claro)
  corNumero,         // números em destaque (âmbar)
  corSucesso,        // verde
  corSucessoFundo,
  corPerigo,         // vermelho
  corBadgeAzul: TColor;

type
  TEstiloBotao = (ebPrimario, ebSecundario, ebPerigo, ebMenu);

  { TBotao - botão pintado, com hover }

  TBotao = class(TCustomControl)
  private
    FEstilo: TEstiloBotao;
    FAtivo: Boolean;
    FHover: Boolean;
    FIcone: string;
    FCorFundo: TColor;
    FModalResult: TModalResult;
    procedure SetAtivo(AValue: Boolean);
  protected
    procedure Paint; override;
    procedure Click; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure TextChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Caption;
    property Estilo: TEstiloBotao read FEstilo write FEstilo;
    property Ativo: Boolean read FAtivo write SetAtivo;
    property Icone: string read FIcone write FIcone;
    { Cor por trás do botão (cantos arredondados) }
    property CorFundo: TColor read FCorFundo write FCorFundo;
    { Como em TButton: ao clicar, fecha o formulário modal com este resultado }
    property ModalResult: TModalResult read FModalResult write FModalResult;
    property OnClick;
  end;

  { TCartao - painel com cantos arredondados e borda }

  TCartao = class(TCustomControl)
  private
    FCor: TColor;
    FCorBorda: TColor;
    FCorFundo: TColor;
    FRaio: Integer;
    FTexto: string;
    FCorTexto: TColor;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    { Coloca um controle dentro da caixa: uma linha (centralizado) ou ocupando tudo }
    procedure Embutir(AControle: TControl; AMultilinha: Boolean = False);
    property Cor: TColor read FCor write FCor;
    property CorBorda: TColor read FCorBorda write FCorBorda;
    property CorFundo: TColor read FCorFundo write FCorFundo;
    property Raio: Integer read FRaio write FRaio;
    { Texto centralizado (usado no logotipo e no avatar) }
    property Texto: string read FTexto write FTexto;
    property CorTexto: TColor read FCorTexto write FCorTexto;
  end;

{ ---------- fábricas ---------- }

function NovoBotao(AOwner: TComponent; AParent: TWinControl; const ACaption: string;
  AEstilo: TEstiloBotao; AEvento: TNotifyEvent; AFundo: TColor): TBotao;
function NovoRotulo(AOwner: TComponent; AParent: TWinControl; const ATexto: string;
  ATamanho: Integer; ACor: TColor; ANegrito: Boolean = False): TLabel;
function NovoCartao(AOwner: TComponent; AParent: TWinControl; AFundo: TColor): TCartao;
{ Caixa de entrada arredondada; o controle de edição deve ser embutido nela }
function NovaCaixa(AOwner: TComponent; AParent: TWinControl; AFundo: TColor): TCartao;
function NovoPainel(AOwner: TComponent; AParent: TWinControl; AAlign: TAlign;
  ACor: TColor; ATamanho: Integer): TPanel;

{ Aplica cores escuras a controles de entrada nativos }
procedure EstilizarEntrada(AControle: TControl);
{ Aplica o tema à tabela }
procedure EstilizarGrade(AGrade: TDBGrid);
{ Largura do texto em pixels (sem depender de handle de janela) }
function LarguraTexto(const ATexto: string; ATamanho: Integer; ANegrito: Boolean = False): Integer;
{ Pinta uma "pílula" (botão de linha da tabela) }
procedure DesenharPilula(ACanvas: TCanvas; const R: TRect; const ATexto: string;
  AEstilo: TEstiloBotao; AFundo: TColor);

{ ---------- diálogos no tema ---------- }

function Confirmar(const ATitulo, AMensagem, ABotaoOk: string;
  APerigo: Boolean = False): Boolean;
procedure Avisar(const ATitulo, AMensagem: string);

implementation

var
  FMedidor: TBitmap = nil;

function LarguraTexto(const ATexto: string; ATamanho: Integer; ANegrito: Boolean): Integer;
begin
  if FMedidor = nil then
  begin
    FMedidor := TBitmap.Create;
    FMedidor.SetSize(4, 4);
  end;
  FMedidor.Canvas.Font.Size := ATamanho;
  if ANegrito then
    FMedidor.Canvas.Font.Style := [fsBold]
  else
    FMedidor.Canvas.Font.Style := [];
  Result := FMedidor.Canvas.TextWidth(ATexto);
end;

{ ---------------------------------------------------------------- }

procedure PintarArredondado(ACanvas: TCanvas; const R: TRect; AFundo, ACor,
  ABorda: TColor; ARaio: Integer);
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AFundo;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(R);
  ACanvas.Brush.Color := ACor;
  if ABorda = clNone then
  begin
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := ACor;
  end
  else
  begin
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := ABorda;
  end;
  ACanvas.Pen.Width := 1;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, ARaio * 2, ARaio * 2);
end;

procedure TextoCentralizado(ACanvas: TCanvas; const R: TRect; const ATexto: string);
var
  TS: TTextStyle;
begin
  TS := ACanvas.TextStyle;
  TS.Alignment := taCenter;
  TS.Layout := tlCenter;
  TS.SingleLine := True;
  TS.Clipping := True;
  TS.Opaque := False;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextRect(R, R.Left, R.Top, ATexto, TS);
end;

procedure DesenharPilula(ACanvas: TCanvas; const R: TRect; const ATexto: string;
  AEstilo: TEstiloBotao; AFundo: TColor);
var
  Cor, Borda, CorTxt: TColor;
begin
  case AEstilo of
    ebPrimario:
      begin
        Cor := corPrimaria; Borda := clNone; CorTxt := clWhite;
      end;
    ebPerigo:
      begin
        Cor := AFundo; Borda := corPerigo; CorTxt := corPerigo;
      end;
  else
    begin
      Cor := AFundo; Borda := corBordaForte; CorTxt := corTexto;
    end;
  end;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := Cor;
  ACanvas.Pen.Style := psSolid;
  if Borda = clNone then
    ACanvas.Pen.Color := Cor
  else
    ACanvas.Pen.Color := Borda;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 10, 10);
  ACanvas.Font.Color := CorTxt;
  ACanvas.Font.Style := [];
  TextoCentralizado(ACanvas, R, ATexto);
end;

{ TBotao }

constructor TBotao.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csClickEvents] - [csSetCaption];
  Cursor := crHandPoint;
  Height := 38;
  Width := 120;
  FCorFundo := corFundo;
  TabStop := False;
end;

procedure TBotao.SetAtivo(AValue: Boolean);
begin
  if FAtivo = AValue then Exit;
  FAtivo := AValue;
  Invalidate;
end;

procedure TBotao.Click;
var
  F: TCustomForm;
begin
  inherited Click;
  if FModalResult <> mrNone then
  begin
    F := GetParentForm(Self);
    if F <> nil then
      F.ModalResult := FModalResult;
  end;
end;

procedure TBotao.MouseEnter;
begin
  inherited MouseEnter;
  FHover := True;
  Invalidate;
end;

procedure TBotao.MouseLeave;
begin
  inherited MouseLeave;
  FHover := False;
  Invalidate;
end;

procedure TBotao.TextChanged;
begin
  inherited TextChanged;
  Invalidate;
end;

procedure TBotao.Paint;
var
  R, RT: TRect;
  Cor, Borda: TColor;
  TS: TTextStyle;
begin
  R := ClientRect;
  Canvas.Font.Assign(Font);
  case FEstilo of
    ebPrimario:
      begin
        if FHover then Cor := corPrimariaHover else Cor := corPrimaria;
        PintarArredondado(Canvas, R, FCorFundo, Cor, clNone, 8);
        Canvas.Font.Color := clWhite;
        Canvas.Font.Style := [fsBold];
        TextoCentralizado(Canvas, R, Caption);
      end;
    ebSecundario, ebPerigo:
      begin
        if FHover then Cor := corHover else Cor := FCorFundo;
        if FEstilo = ebPerigo then Borda := corPerigo else Borda := corBordaForte;
        PintarArredondado(Canvas, R, FCorFundo, Cor, Borda, 8);
        if FEstilo = ebPerigo then
          Canvas.Font.Color := corPerigo
        else
          Canvas.Font.Color := corTexto;
        TextoCentralizado(Canvas, R, Caption);
      end;
    ebMenu:
      begin
        if FAtivo then Cor := corSelecao
        else if FHover then Cor := corHover
        else Cor := FCorFundo;
        PintarArredondado(Canvas, R, FCorFundo, Cor, clNone, 8);
        if FAtivo then
        begin
          Canvas.Brush.Color := corPrimaria;
          Canvas.Pen.Color := corPrimaria;
          Canvas.FillRect(Rect(R.Left, R.Top + 6, R.Left + 3, R.Bottom - 6));
          Canvas.Font.Color := clWhite;
          Canvas.Font.Style := [fsBold];
        end
        else
        begin
          Canvas.Font.Color := corTextoMenu;
          Canvas.Font.Style := [fsBold];
        end;
        TS := Canvas.TextStyle;
        TS.Alignment := taLeftJustify;
        TS.Layout := tlCenter;
        TS.SingleLine := True;
        TS.Opaque := False;
        Canvas.Brush.Style := bsClear;
        RT := Rect(R.Left + 14, R.Top, R.Left + 38, R.Bottom);
        Canvas.TextRect(RT, RT.Left, RT.Top, FIcone, TS);
        RT := Rect(R.Left + 40, R.Top, R.Right - 6, R.Bottom);
        Canvas.TextRect(RT, RT.Left, RT.Top, Caption, TS);
      end;
  end;
end;

{ TCartao }

constructor TCartao.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCor := corCartao;
  FCorBorda := corBorda;
  FCorFundo := corFundo;
  FCorTexto := clWhite;
  FRaio := 12;
  ControlStyle := ControlStyle + [csAcceptsControls];
end;

procedure TCartao.Paint;
begin
  PintarArredondado(Canvas, ClientRect, FCorFundo, FCor, FCorBorda, FRaio);
  if FTexto <> '' then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Color := FCorTexto;
    TextoCentralizado(Canvas, ClientRect, FTexto);
  end;
end;

procedure TCartao.Embutir(AControle: TControl; AMultilinha: Boolean);
begin
  AControle.Parent := Self;
  if AMultilinha then
  begin
    AControle.Align := alClient;
    AControle.BorderSpacing.Around := 8;
  end
  else
  begin
    AControle.AnchorSide[akLeft].Control := Self;
    AControle.AnchorSide[akLeft].Side := asrLeft;
    AControle.AnchorSide[akRight].Control := Self;
    AControle.AnchorSide[akRight].Side := asrRight;
    AControle.BorderSpacing.Left := 12;
    AControle.BorderSpacing.Right := 12;
    AControle.AnchorVerticalCenterTo(Self);
    AControle.Anchors := [akLeft, akRight, akTop];
  end;
end;

{ ---------------------------------------------------------------- }

function NovoBotao(AOwner: TComponent; AParent: TWinControl; const ACaption: string;
  AEstilo: TEstiloBotao; AEvento: TNotifyEvent; AFundo: TColor): TBotao;
var
  W: Integer;
begin
  Result := TBotao.Create(AOwner);
  Result.Parent := AParent;
  Result.Estilo := AEstilo;
  Result.Caption := ACaption;
  Result.CorFundo := AFundo;
  Result.OnClick := AEvento;
  Result.Font.Size := 10;
  W := LarguraTexto(ACaption, 10, AEstilo = ebPrimario);
  Result.Width := Max(84, W + 40);
end;

function NovoRotulo(AOwner: TComponent; AParent: TWinControl; const ATexto: string;
  ATamanho: Integer; ACor: TColor; ANegrito: Boolean): TLabel;
begin
  Result := TLabel.Create(AOwner);
  Result.Parent := AParent;
  Result.Caption := ATexto;
  Result.Font.Size := ATamanho;
  Result.Font.Color := ACor;
  if ANegrito then
    Result.Font.Style := [fsBold];
  Result.Transparent := True;
end;

function NovoCartao(AOwner: TComponent; AParent: TWinControl; AFundo: TColor): TCartao;
begin
  Result := TCartao.Create(AOwner);
  Result.Parent := AParent;
  Result.CorFundo := AFundo;
end;

function NovaCaixa(AOwner: TComponent; AParent: TWinControl; AFundo: TColor): TCartao;
begin
  Result := NovoCartao(AOwner, AParent, AFundo);
  Result.Cor := corEntrada;
  Result.CorBorda := corBordaForte;
  Result.Raio := 8;
  Result.Height := 42;
end;

function NovoPainel(AOwner: TComponent; AParent: TWinControl; AAlign: TAlign;
  ACor: TColor; ATamanho: Integer): TPanel;
begin
  Result := TPanel.Create(AOwner);
  Result.Parent := AParent;
  Result.BevelOuter := bvNone;
  Result.Color := ACor;
  Result.ParentColor := False;
  Result.Align := AAlign;
  if AAlign in [alTop, alBottom] then
    Result.Height := ATamanho
  else if AAlign in [alLeft, alRight] then
    Result.Width := ATamanho;
end;

procedure EstilizarEntrada(AControle: TControl);
begin
  AControle.Color := corEntrada;
  AControle.Font.Color := corTexto;
  AControle.Font.Size := 10;
  if AControle is TCustomEdit then
    TCustomEdit(AControle).BorderStyle := bsNone;
end;

procedure EstilizarGrade(AGrade: TDBGrid);
begin
  AGrade.BorderStyle := bsNone;
  AGrade.Flat := True;
  AGrade.Color := corCartao;
  AGrade.FixedColor := corCartao;
  AGrade.AlternateColor := corCartao;
  AGrade.SelectedColor := corSelecao;
  AGrade.FocusColor := corSelecao;
  AGrade.GridLineColor := corBorda;
  AGrade.Font.Color := corTexto;
  AGrade.Font.Size := 10;
  AGrade.TitleFont.Color := corTextoSuave;
  AGrade.TitleFont.Size := 8;
  AGrade.TitleFont.Style := [fsBold];
  AGrade.TitleStyle := tsStandard;
  AGrade.DefaultRowHeight := 46;
  AGrade.FocusRectVisible := False;
  AGrade.Options := [dgTitles, dgRowLines, dgRowSelect, dgAlwaysShowSelection,
    dgCancelOnExit, dgDisableDelete, dgDisableInsert];
  AGrade.ReadOnly := True;
  AGrade.AutoFillColumns := True;
end;

{ ---------------- diálogos ---------------- }

type
  TDialogoTema = class(TForm)
  public
    constructor Criar(const ATitulo, AMensagem, ABotaoOk: string;
      APerigo, ASoOk: Boolean);
  end;

constructor TDialogoTema.Criar(const ATitulo, AMensagem, ABotaoOk: string;
  APerigo, ASoOk: Boolean);
var
  Lbl: TLabel;
  B: TBotao;
  Rodape: TPanel;
begin
  inherited CreateNew(nil);
  BorderStyle := bsDialog;
  Caption := ATitulo;
  Position := poMainFormCenter;
  Color := corCartao;
  Width := 460;
  Height := 210;
  KeyPreview := True;

  Lbl := NovoRotulo(Self, Self, ATitulo, 14, corTexto, True);
  Lbl.SetBounds(24, 20, 410, 26);

  Lbl := NovoRotulo(Self, Self, AMensagem, 10, corTextoSuave);
  Lbl.WordWrap := True;
  Lbl.AutoSize := False;
  if Length(AMensagem) > 160 then
  begin
    Width := 620;
    Height := 300;
    Lbl.SetBounds(24, 56, 570, 170);
  end
  else
    Lbl.SetBounds(24, 56, 410, 80);

  Rodape := NovoPainel(Self, Self, alBottom, corCartao, 64);

  B := NovoBotao(Self, Rodape, ABotaoOk, ebPrimario, nil, corCartao);
  if APerigo then
    B.Estilo := ebPerigo;
  B.ModalResult := mrOK;
  B.SetBounds(Width - B.Width - 24, 12, B.Width, 40);

  if not ASoOk then
  begin
    B := NovoBotao(Self, Rodape, 'Cancelar', ebSecundario, nil, corCartao);
    B.ModalResult := mrCancel;
    B.SetBounds(Width - B.Width - 24 - 140, 12, 120, 40);
  end;
end;

function Confirmar(const ATitulo, AMensagem, ABotaoOk: string;
  APerigo: Boolean): Boolean;
var
  D: TDialogoTema;
begin
  D := TDialogoTema.Criar(ATitulo, AMensagem, ABotaoOk, APerigo, False);
  try
    Result := D.ShowModal = mrOK;
  finally
    D.Free;
  end;
end;

procedure Avisar(const ATitulo, AMensagem: string);
var
  D: TDialogoTema;
begin
  D := TDialogoTema.Criar(ATitulo, AMensagem, 'OK', False, True);
  try
    D.ShowModal;
  finally
    D.Free;
  end;
end;

initialization
  corFundo         := RGBToColor($0B, $12, $20);
  corLateral       := RGBToColor($0A, $10, $1D);
  corCartao        := RGBToColor($0F, $17, $2A);
  corEntrada       := RGBToColor($0B, $12, $20);
  corBorda         := RGBToColor($1E, $29, $3B);
  corBordaForte    := RGBToColor($33, $41, $55);
  corSelecao       := RGBToColor($17, $25, $54);
  corHover         := RGBToColor($15, $1F, $35);
  corPrimaria      := RGBToColor($25, $63, $EB);
  corPrimariaHover := RGBToColor($1D, $4E, $D8);
  corTexto         := RGBToColor($F1, $F5, $F9);
  corTextoSuave    := RGBToColor($94, $A3, $B8);
  corTextoMenu     := RGBToColor($CB, $D5, $E1);
  corDestaque      := RGBToColor($93, $C5, $FD);
  corNumero        := RGBToColor($F5, $9E, $0B);
  corSucesso       := RGBToColor($22, $C5, $5E);
  corSucessoFundo  := RGBToColor($14, $53, $2D);
  corPerigo        := RGBToColor($F8, $71, $71);
  corBadgeAzul     := RGBToColor($1E, $3A, $8A);

finalization
  FMedidor.Free;

end.
