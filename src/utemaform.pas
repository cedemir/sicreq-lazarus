unit uTemaForm;

{ Tema para formulários desenhados no designer do Lazarus (.lfm).

  No designer usam-se só componentes padrão; a propriedade Tag indica o
  papel visual de cada um, e AplicarTema faz a troca ao abrir a tela:

    TButton  Tag = 1  -> TBotao primário (azul)
    TButton  Tag = 2  -> TBotao secundário (contorno)
    TButton  Tag = 3  -> TBotao perigo (vermelho)
    TPanel   Tag = 10 -> caixa de entrada arredondada (coloque o TEdit dentro)
    TPanel   Tag = 11 -> cartão arredondado com borda
    TPanel   Tag = 12 -> logotipo (quadrado azul arredondado com o Caption)

  Os TComboBox são trocados explicitamente com TrocarCombo, porque o
  código precisa da referência ao TCaixaEscolha para preencher os itens. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, Graphics, DBCtrls,
  uTema, uEscolha;

const
  TAG_BOTAO_PRIMARIO   = 1;
  TAG_BOTAO_SECUNDARIO = 2;
  TAG_BOTAO_PERIGO     = 3;
  TAG_CAIXA            = 10;
  TAG_CARTAO           = 11;
  TAG_LOGO             = 12;

{ Troca os botões marcados e liga a pintura dos painéis marcados.
  ARaiz: o formulário ou o frame (dono dos componentes do .lfm). }
procedure AplicarTema(ARaiz: TComponent);
{ Troca um TDBLookupComboBox pela combo escura, ligada ao mesmo campo }
function TrocarLookup(ALookup: TDBLookupComboBox): TCaixaEscolha;
{ Controle que está na tela no lugar do componente ANome (o trocado, se houve) }
function ControleNaTela(ARaiz: TComponent; const ANome: string): TControl;
{ Troca um TButton por um TBotao no mesmo lugar (mantém OnClick e ModalResult) }
function TrocarBotao(AButton: TButton): TBotao;
{ Troca um TComboBox por um TCaixaEscolha no mesmo lugar (itens ficam vazios) }
function TrocarCombo(ACombo: TComboBox): TCaixaEscolha;

implementation

type
  TPintorTema = class
    procedure PintarCaixa(Sender: TObject);
    procedure PintarCartao(Sender: TObject);
    procedure PintarLogo(Sender: TObject);
  end;

var
  FPintor: TPintorTema = nil;

{ cor visível atrás do controle (para os cantos arredondados) }
function CorDoPai(AControle: TControl): TColor;
begin
  if AControle.Parent is TCustomForm then
    Result := TCustomForm(AControle.Parent).Color
  else if AControle.Parent is TPanel then
    Result := TPanel(AControle.Parent).Color
  else
    Result := corCartao;
end;

{ copia as âncoras laterais (ex.: centralizado no formulário) }
procedure CopiarAncoras(ADe, APara: TControl);
var
  K: TAnchorKind;
begin
  for K := Low(TAnchorKind) to High(TAnchorKind) do
  begin
    APara.AnchorSide[K].Control := ADe.AnchorSide[K].Control;
    APara.AnchorSide[K].Side := ADe.AnchorSide[K].Side;
  end;
  APara.Anchors := ADe.Anchors;
end;

{ controles irmãos ancorados no original passam a ancorar no substituto }
procedure RedirecionarAncoras(ADe, APara: TControl);
var
  I: Integer;
  K: TAnchorKind;
  C: TControl;
begin
  if ADe.Parent = nil then
    Exit;
  for I := 0 to ADe.Parent.ControlCount - 1 do
  begin
    C := ADe.Parent.Controls[I];
    if (C = ADe) or (C = APara) then
      Continue;
    for K := Low(TAnchorKind) to High(TAnchorKind) do
      if C.AnchorSide[K].Control = ADe then
        C.AnchorSide[K].Control := APara;
  end;
end;

{ prepara o substituto no lugar do original e esconde o original }
procedure Substituir(ADe, APara: TControl);
begin
  APara.Align := ADe.Align;
  APara.BorderSpacing.Assign(ADe.BorderSpacing);
  APara.BoundsRect := ADe.BoundsRect;
  APara.Parent := ADe.Parent;
  CopiarAncoras(ADe, APara);
  RedirecionarAncoras(ADe, APara);
  APara.Visible := ADe.Visible;
  APara.Hint := ADe.Hint;
  APara.ShowHint := ADe.ShowHint;
  { o nome do original identifica o substituto (ver ControleNaTela) }
  APara.HelpKeyword := ADe.Name;
  ADe.Visible := False;
end;

procedure Arredondado(APainel: TPanel; ACor, ABorda: TColor; ARaio: Integer);
var
  C: TCanvas;
  R: TRect;
begin
  C := APainel.Canvas;
  R := APainel.ClientRect;
  C.Brush.Style := bsSolid;
  C.Brush.Color := CorDoPai(APainel);
  C.FillRect(R);
  C.Brush.Color := ACor;
  C.Pen.Style := psSolid;
  C.Pen.Width := 1;
  if ABorda = clNone then
    C.Pen.Color := ACor
  else
    C.Pen.Color := ABorda;
  C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, ARaio * 2, ARaio * 2);
end;

procedure TPintorTema.PintarCaixa(Sender: TObject);
begin
  Arredondado(TPanel(Sender), corEntrada, corBordaForte, 8);
end;

procedure TPintorTema.PintarCartao(Sender: TObject);
begin
  Arredondado(TPanel(Sender), corCartao, corBorda, 14);
end;

procedure TPintorTema.PintarLogo(Sender: TObject);
var
  P: TPanel;
  TS: TTextStyle;
begin
  P := TPanel(Sender);
  Arredondado(P, corPrimaria, clNone, 12);
  P.Canvas.Font.Assign(P.Font);
  P.Canvas.Font.Color := clWhite;
  TS := P.Canvas.TextStyle;
  TS.Alignment := taCenter;
  TS.Layout := tlCenter;
  TS.Opaque := False;
  P.Canvas.Brush.Style := bsClear;
  P.Canvas.TextRect(P.ClientRect, 0, 0, P.Caption, TS);
end;

function TrocarBotao(AButton: TButton): TBotao;
begin
  Result := TBotao.Create(AButton.Owner);
  case AButton.Tag of
    TAG_BOTAO_PRIMARIO: Result.Estilo := ebPrimario;
    TAG_BOTAO_PERIGO: Result.Estilo := ebPerigo;
  else
    Result.Estilo := ebSecundario;
  end;
  Result.Caption := AButton.Caption;
  Result.OnClick := AButton.OnClick;
  Result.ModalResult := AButton.ModalResult;
  Result.Font.Size := 10;
  Result.CorFundo := CorDoPai(AButton);
  Substituir(AButton, Result);
  { o original fica escondido e sem efeito no Enter/Esc }
  AButton.Default := False;
  AButton.Cancel := False;
end;

function TrocarCombo(ACombo: TComboBox): TCaixaEscolha;
begin
  Result := TCaixaEscolha.Create(ACombo.Owner);
  Result.CorFundo := CorDoPai(ACombo);
  Substituir(ACombo, Result);
  if Result.Align = alNone then
    Result.Height := 42;
  Result.TabOrder := ACombo.TabOrder;
end;

function TrocarLookup(ALookup: TDBLookupComboBox): TCaixaEscolha;
begin
  Result := TCaixaEscolha.Create(ALookup.Owner);
  Result.CorFundo := CorDoPai(ALookup);
  Result.ReadOnly := ALookup.ReadOnly;
  Substituir(ALookup, Result);
  Result.Height := 42;
  Result.TabOrder := ALookup.TabOrder;
  Result.DataSource := ALookup.DataSource;
  Result.DataField := ALookup.DataField;
  ALookup.DataSource := nil;   // o original não edita mais o campo
end;

function ControleNaTela(ARaiz: TComponent; const ANome: string): TControl;
var
  I: Integer;
  C: TComponent;
begin
  for I := 0 to ARaiz.ComponentCount - 1 do
  begin
    C := ARaiz.Components[I];
    if (C is TControl) and (TControl(C).HelpKeyword = ANome) and (C.Name = '') then
      Exit(TControl(C));
  end;
  C := ARaiz.FindComponent(ANome);
  if C is TControl then
    Result := TControl(C)
  else
    Result := nil;
end;

procedure AplicarTema(ARaiz: TComponent);
var
  Lista: TFPList;
  I: Integer;
  C: TComponent;
begin
  if FPintor = nil then
    FPintor := TPintorTema.Create;
  { copia a lista antes: TrocarBotao cria componentes no mesmo dono }
  Lista := TFPList.Create;
  try
    for I := 0 to ARaiz.ComponentCount - 1 do
      Lista.Add(ARaiz.Components[I]);
    for I := 0 to Lista.Count - 1 do
    begin
      C := TComponent(Lista[I]);
      if (C is TButton) and (C.Tag in [TAG_BOTAO_PRIMARIO, TAG_BOTAO_SECUNDARIO, TAG_BOTAO_PERIGO]) then
        TrocarBotao(TButton(C))
      else if C is TPanel then
        case C.Tag of
          TAG_CAIXA: TPanel(C).OnPaint := @FPintor.PintarCaixa;
          TAG_CARTAO: TPanel(C).OnPaint := @FPintor.PintarCartao;
          TAG_LOGO: TPanel(C).OnPaint := @FPintor.PintarLogo;
        end;
    end;
  finally
    Lista.Free;
  end;
end;

finalization
  FPintor.Free;

end.
