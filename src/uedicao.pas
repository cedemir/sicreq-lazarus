unit uEdicao;

{ Inclusão/edição de um registro.

  O visual de cada tabela é um TForm desenhado no designer, em
  src/telas/ueditar<tabela>.pas/.lfm (registrado em uTelas). Esta unit
  cria o formulário e um controlador (TEdicaoTela) que adota os
  componentes pelo nome:

    QryRegistro / DsRegistro      o registro (SELECT * ... WHERE chave = :k)
    Lbl_<campo>, Edt_<campo>      rótulo e controle DB de cada campo
    Pnl_<campo>                   caixa arredondada do campo (Tag 10)
    BtnArq_<campo>, BtnVer_<campo> escolher / ver imagem
    BtnSalvar, BtnCancelar, LblTitulo, LblTrilha, LblDica

  Regras (obrigatórios, numeração automática, valores padrão, consultas
  das listas) vêm de uDefinicoes. Os TDBLookupComboBox viram a combo
  escura (TCaixaEscolha) ligada ao mesmo campo. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, StrUtils, Math, TypInfo, Forms, Controls,
  StdCtrls, ExtCtrls, Graphics, Dialogs, ExtDlgs, DBCtrls, DB, LCLType,
  LazFileUtils, LazUTF8, ZDataset, uDefinicoes, uTema, uTemaForm, uEscolha,
  uTelas;

{ Abre o formulário da tabela. AChave = Null para incluir.
  Retorna True se gravou; AChaveGravada recebe a chave do registro. }
function EditarRegistro(ADef: TTabelaDef; const AChave: Variant;
  const AFixos: TFiltrosFixos; const ATrilha: string;
  out AChaveGravada: Variant; ASomenteLeitura: Boolean = False): Boolean;

{ Pasta padrão das imagens e resolução de caminhos relativos }
function PastaImagens: string;
function CaminhoImagem(const AArquivo: string): string;
procedure MostrarImagem(const AArquivo: string);

implementation

uses
  uDM;

type

  { TEdicaoTela - comportamento comum a todos os formulários de edição }

  TEdicaoTela = class(TComponent)
  private
    FForm: TCustomForm;
    FDef: TTabelaDef;
    FFixos: TFiltrosFixos;
    FSomenteLeitura: Boolean;
    Qry: TZQuery;
    Ds: TDataSource;
    FCaixas: TStringList;     // campo -> TCaixaEscolha (lookups trocados)
    function Comp(const ANome: string; AObrigatorio: Boolean = True): TComponent;
    function CampoFixo(const ANome: string): Boolean;
    function ControleDoCampo(const ANome: string): TWinControl;
    function CampoDoBotao(Sender: TObject; const APrefixo: string): string;
    function ProximoNumero(const ACampo: string): Integer;
    procedure Esconder(const ANome: string);
    procedure FocarPrimeiro;
    procedure QryAfterOpen(DataSet: TDataSet);
    procedure SalvarClick(Sender: TObject);
    procedure ArquivoClick(Sender: TObject);
    procedure VerClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  public
    ChaveGravada: Variant;
    constructor Criar(AForm: TCustomForm; ADef: TTabelaDef; const AChave: Variant;
      const AFixos: TFiltrosFixos; const ATrilha: string; ASomenteLeitura: Boolean);
    destructor Destroy; override;
  end;

{ ------------------------------------------------------------------ }

function PastaImagens: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'imagens');
end;

function CaminhoImagem(const AArquivo: string): string;
begin
  if (AArquivo = '') or FilenameIsAbsolute(AArquivo) then
    Result := AArquivo
  else
    Result := PastaImagens + AArquivo;
end;

procedure MostrarImagem(const AArquivo: string);
var
  Arq: string;
  F: TForm;
  Img: TImage;
begin
  Arq := CaminhoImagem(AArquivo);
  if (Arq = '') or not FileExists(Arq) then
  begin
    Avisar('Imagem não encontrada', 'O arquivo não existe:' + LineEnding + Arq);
    Exit;
  end;
  F := TForm.CreateNew(nil);
  try
    F.Caption := ExtractFileName(Arq);
    F.Position := poMainFormCenter;
    F.Color := corFundo;
    F.SetBounds(0, 0, 560, 760);
    Img := TImage.Create(F);
    Img.Parent := F;
    Img.Align := alClient;
    Img.BorderSpacing.Around := 12;
    Img.Stretch := True;
    Img.Proportional := True;
    Img.Center := True;
    try
      Img.Picture.LoadFromFile(Arq);
    except
      on E: Exception do
      begin
        Avisar('Imagem inválida', E.Message);
        Exit;
      end;
    end;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

{ ------------------------------------------------------------------ }
{ TEdicaoTela                                                         }
{ ------------------------------------------------------------------ }

function TEdicaoTela.Comp(const ANome: string; AObrigatorio: Boolean): TComponent;
begin
  Result := FForm.FindComponent(ANome);
  if (Result = nil) and AObrigatorio then
    raise Exception.CreateFmt('A tela %s não tem o componente "%s" (não renomeie os ' +
      'componentes usados pelo sistema).', [FForm.ClassName, ANome]);
end;

function TEdicaoTela.CampoFixo(const ANome: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FFixos) do
    if SameText(FFixos[I].Campo, ANome) then
      Exit(True);
  Result := False;
end;

function TEdicaoTela.ControleDoCampo(const ANome: string): TWinControl;
var
  I: Integer;
  C: TComponent;
begin
  I := FCaixas.IndexOf(ANome);
  if I >= 0 then
    Exit(TWinControl(FCaixas.Objects[I]));
  C := Comp('Edt_' + ANome, False);
  if C is TWinControl then
    Result := TWinControl(C)
  else
    Result := nil;
end;

{ BtnArq_<campo> / BtnVer_<campo>: o substituto (TBotao) guarda o nome do
  original em HelpKeyword }
function TEdicaoTela.CampoDoBotao(Sender: TObject; const APrefixo: string): string;
var
  N: string;
begin
  N := TControl(Sender).Name;
  if N = '' then
    N := TControl(Sender).HelpKeyword;
  if AnsiStartsText(APrefixo, N) then
    Result := Copy(N, Length(APrefixo) + 1, MaxInt)
  else
    Result := '';
end;

procedure TEdicaoTela.Esconder(const ANome: string);
var
  C: TComponent;
begin
  C := Comp(ANome, False);
  if C is TControl then
    TControl(C).Visible := False;
end;

constructor TEdicaoTela.Criar(AForm: TCustomForm; ADef: TTabelaDef;
  const AChave: Variant; const AFixos: TFiltrosFixos; const ATrilha: string;
  ASomenteLeitura: Boolean);
var
  I: Integer;
  C: TCampoDef;
  Titulo: string;
  Ctl: TComponent;
  L: TDBLookupComboBox;
  Caixa: TCaixaEscolha;
  QL: TZReadOnlyQuery;
begin
  inherited Create(AForm);
  FForm := AForm;
  FDef := ADef;
  FFixos := AFixos;
  FSomenteLeitura := ASomenteLeitura;
  FCaixas := TStringList.Create;
  ChaveGravada := Null;

  { --- dados --- }
  Qry := Comp('QryRegistro') as TZQuery;
  Qry.Connection := DM.Conexao;
  Qry.SQL.Text := Format('SELECT * FROM %s WHERE %s = :k', [FDef.Tabela, FDef.Chave]);
  Qry.AfterOpen := @QryAfterOpen;
  Ds := Comp('DsRegistro') as TDataSource;
  Ds.DataSet := Qry;
  Ds.AutoEdit := not FSomenteLeitura;

  if VarIsNull(AChave) then
    Qry.ParamByName('k').AsInteger := -1
  else
    Qry.ParamByName('k').Value := AChave;
  Qry.Open;

  if VarIsNull(AChave) then
  begin
    Titulo := FDef.TextoNovo;
    Qry.Append;
    for I := 0 to High(FFixos) do
      Qry.FieldByName(FFixos[I].Campo).Value := FFixos[I].Valor;
    for I := 0 to High(FDef.Campos) do
      if not VarIsNull(FDef.Campos[I].Padrao) and not CampoFixo(FDef.Campos[I].Nome) then
        Qry.FieldByName(FDef.Campos[I].Nome).Value := FDef.Campos[I].Padrao;
    for I := 0 to High(FDef.Campos) do
      if ocAutoNumero in FDef.Campos[I].Opcoes then
        Qry.FieldByName(FDef.Campos[I].Nome).AsInteger := ProximoNumero(FDef.Campos[I].Nome);
  end
  else
  begin
    if Qry.IsEmpty then
      raise Exception.Create('Registro não encontrado (pode ter sido excluído).');
    if FSomenteLeitura then
      Titulo := 'Detalhes do registro'
    else
    begin
      Titulo := 'Editar ' + FDef.NomeSingular;
      Qry.Edit;
    end;
  end;

  { --- textos --- }
  FForm.Caption := Titulo;
  (Comp('LblTitulo') as TLabel).Caption := Titulo;
  Ctl := Comp('LblTrilha', False);
  if Ctl is TLabel then
    TLabel(Ctl).Caption := ATrilha;

  { --- campos ligados ao mestre: ficam ocultos --- }
  for I := 0 to High(FFixos) do
  begin
    Esconder('Lbl_' + FFixos[I].Campo);
    Esconder('Pnl_' + FFixos[I].Campo);
    Esconder('Edt_' + FFixos[I].Campo);
  end;

  { --- modo leitura (perfil Consulta) --- }
  if FSomenteLeitura then
  begin
    for I := 0 to High(FDef.Campos) do
    begin
      Ctl := Comp('Edt_' + FDef.Campos[I].Nome, False);
      if (Ctl <> nil) and IsPublishedProp(Ctl, 'ReadOnly') then
        SetOrdProp(Ctl, 'ReadOnly', Ord(True));
      Esconder('BtnArq_' + FDef.Campos[I].Nome);
    end;
    Esconder('BtnSalvar');
    (Comp('BtnCancelar') as TButton).Caption := 'Fechar';
    Ctl := Comp('LblDica', False);
    if Ctl is TLabel then
      TLabel(Ctl).Caption := 'Somente leitura (perfil Consulta)';
  end;

  { --- eventos (antes de AplicarTema: os botões trocados copiam o OnClick) --- }
  (Comp('BtnSalvar') as TButton).OnClick := @SalvarClick;
  for I := 0 to High(FDef.Campos) do
  begin
    Ctl := Comp('BtnArq_' + FDef.Campos[I].Nome, False);
    if Ctl is TButton then
      TButton(Ctl).OnClick := @ArquivoClick;
    Ctl := Comp('BtnVer_' + FDef.Campos[I].Nome, False);
    if Ctl is TButton then
      TButton(Ctl).OnClick := @VerClick;
  end;
  FForm.KeyPreview := True;
  FForm.OnKeyDown := @FormKeyDown;
  FForm.OnCloseQuery := @FormCloseQuery;
  FForm.OnShow := @FormShow;

  AplicarTema(FForm);

  { --- listas (lookups) viram a combo escura --- }
  for I := 0 to High(FDef.Campos) do
  begin
    C := FDef.Campos[I];
    if C.Tipo <> tcLookup then
      Continue;
    Ctl := Comp('Edt_' + C.Nome, False);
    if not (Ctl is TDBLookupComboBox) then
      Continue;
    L := TDBLookupComboBox(Ctl);
    Caixa := TrocarLookup(L);
    Caixa.ReadOnly := FSomenteLeitura or (ocSomenteLeitura in C.Opcoes);
    QL := DM.NovaConsulta(nil, C.LookupSQL);
    try
      QL.Open;
      Caixa.CarregarDe(QL);
    finally
      QL.Free;
    end;
    Caixa.Valor := Qry.FieldByName(C.Nome).Value;
    FCaixas.AddObject(C.Nome, Caixa);
  end;
end;

destructor TEdicaoTela.Destroy;
begin
  FCaixas.Free;
  inherited Destroy;
end;

function TEdicaoTela.ProximoNumero(const ACampo: string): Integer;
var
  S, Where: string;
  Valores: array of Variant;
  I: Integer;
  V: Variant;
begin
  Where := '';
  SetLength(Valores, Length(FFixos));
  for I := 0 to High(FFixos) do
  begin
    Where := Where + StrUtils.IfThen(Where <> '', ' AND ', '') +
      Format('%s = :f%d', [FFixos[I].Campo, I]);
    Valores[I] := FFixos[I].Valor;
  end;
  S := Format('SELECT COALESCE(MAX(%s), 0) + 1 FROM %s', [ACampo, FDef.Tabela]);
  if Where <> '' then
    S := S + ' WHERE ' + Where;
  V := DM.ValorSQL(S, Valores);
  if VarIsNull(V) then
    Result := 1
  else
    Result := V;
end;

procedure TEdicaoTela.FocarPrimeiro;
var
  I: Integer;
  W: TWinControl;
begin
  for I := 0 to High(FDef.Campos) do
  begin
    if CampoFixo(FDef.Campos[I].Nome) or
       (ocSomenteLeitura in FDef.Campos[I].Opcoes) or
       (ocAutoNumero in FDef.Campos[I].Opcoes) then
      Continue;
    W := ControleDoCampo(FDef.Campos[I].Nome);
    if (W <> nil) and W.CanFocus then
    begin
      W.SetFocus;
      Exit;
    end;
  end;
end;

procedure TEdicaoTela.QryAfterOpen(DataSet: TDataSet);
var
  I: Integer;
begin
  { obrigatórios são validados em SalvarClick, com mensagens próprias }
  for I := 0 to DataSet.FieldCount - 1 do
  begin
    DataSet.Fields[I].Required := False;
    if DataSet.Fields[I] is TDateTimeField then
      TDateTimeField(DataSet.Fields[I]).DisplayFormat := 'dd/mm/yyyy';
  end;
end;

procedure TEdicaoTela.FormShow(Sender: TObject);
begin
  FocarPrimeiro;
end;

procedure TEdicaoTela.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  { com uma lista de escolha aberta, Esc/Enter são dela (não do diálogo) }
  if EscolhaAberta then
    Exit;
  case Key of
    VK_F2:
      begin
        Key := 0;
        if not FSomenteLeitura then
          SalvarClick(nil);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        FForm.ModalResult := mrCancel;
      end;
  end;
end;

procedure TEdicaoTela.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (FForm.ModalResult <> mrOK) and (Qry.State in [dsEdit, dsInsert]) then
    Qry.Cancel;
end;

procedure TEdicaoTela.SalvarClick(Sender: TObject);
var
  I: Integer;
  F: TField;
  W: TWinControl;
  Chave: Variant;
begin
  Qry.UpdateRecord;
  for I := 0 to High(FDef.Campos) do
    if (ocObrigatorio in FDef.Campos[I].Opcoes) and not CampoFixo(FDef.Campos[I].Nome) then
    begin
      F := Qry.FieldByName(FDef.Campos[I].Nome);
      if F.IsNull or (Trim(F.AsString) = '') then
      begin
        Avisar('Campo obrigatório', Format('Informe o campo "%s".', [FDef.Campos[I].Rotulo]));
        W := ControleDoCampo(FDef.Campos[I].Nome);
        if (W <> nil) and W.CanFocus then
          W.SetFocus;
        Exit;
      end;
    end;

  try
    Qry.Post;
  except
    on E: Exception do
    begin
      Avisar('Não foi possível salvar', E.Message);
      Exit;
    end;
  end;

  Chave := Qry.FieldByName(FDef.Chave).Value;
  if VarIsNull(Chave) or (Chave = 0) then
    Chave := DM.ValorSQL('SELECT LAST_INSERT_ID()', []);
  ChaveGravada := Chave;
  FForm.ModalResult := mrOK;
end;

procedure TEdicaoTela.ArquivoClick(Sender: TObject);
var
  Dlg: TOpenPictureDialog;
  F: TField;
  Arq, Campo: string;
begin
  Campo := CampoDoBotao(Sender, 'BtnArq_');
  if Campo = '' then
    Exit;
  Dlg := TOpenPictureDialog.Create(Self);
  try
    Dlg.Title := 'Selecionar imagem';
    if DirectoryExists(PastaImagens) then
      Dlg.InitialDir := PastaImagens;
    if not Dlg.Execute then
      Exit;
    Arq := Dlg.FileName;
    { Imagens dentro da pasta "imagens" são gravadas com caminho relativo }
    if AnsiStartsText(PastaImagens, Arq) then
      Arq := Copy(Arq, Length(PastaImagens) + 1, MaxInt);
    F := Qry.FieldByName(Campo);
    if (F.Size > 0) and (Length(Arq) > F.Size) then
    begin
      Avisar('Caminho muito longo', Format('O caminho tem %d caracteres e o campo ' +
        'aceita %d. Copie a imagem para a pasta:' + LineEnding + '%s',
        [Length(Arq), F.Size, PastaImagens]));
      Exit;
    end;
    if not (Qry.State in [dsEdit, dsInsert]) then
      Qry.Edit;
    F.AsString := Arq;
  finally
    Dlg.Free;
  end;
end;

procedure TEdicaoTela.VerClick(Sender: TObject);
var
  Campo: string;
begin
  Campo := CampoDoBotao(Sender, 'BtnVer_');
  if Campo = '' then
    Exit;
  if Qry.State in [dsEdit, dsInsert] then
    Qry.UpdateRecord;
  MostrarImagem(Qry.FieldByName(Campo).AsString);
end;

{ ------------------------------------------------------------------ }

function EditarRegistro(ADef: TTabelaDef; const AChave: Variant;
  const AFixos: TFiltrosFixos; const ATrilha: string;
  out AChaveGravada: Variant; ASomenteLeitura: Boolean): Boolean;
var
  F: TCustomForm;
  Tela: TEdicaoTela;
begin
  AChaveGravada := Null;
  F := ClasseEdicao(ADef.Tabela).Create(nil);
  try
    Tela := TEdicaoTela.Criar(F, ADef, AChave, AFixos, ATrilha, ASomenteLeitura);
    Result := F.ShowModal = mrOK;
    if Result then
      AChaveGravada := Tela.ChaveGravada;
  finally
    F.Free;
  end;
end;

end.
