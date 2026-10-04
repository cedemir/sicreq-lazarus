unit uLogin;

{ Tela de login. Formulário visual: ulogin.lfm (tema aplicado por
  AplicarTema - veja uTemaForm).

  - Se ainda não existe nenhum usuário, a tela vira "Primeiro acesso" e
    cria o administrador (o .lfm está desenhado neste modo; no login
    normal os grupos Nome e Confirmar ficam ocultos).
  - O último login usado fica em sicreq.ini (nunca a senha).
  - Cada tentativa errada espera um pouco mais (dificulta adivinhação). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, IniFiles, Forms, Controls, StdCtrls, ExtCtrls,
  Graphics, LCLType, uTema, uTemaForm, uSessao;

type

  { TFrmLogin }

  TFrmLogin = class(TForm)
    BtnConexao: TButton;
    BtnEntrar: TButton;
    EdtConfirma: TEdit;
    EdtLogin: TEdit;
    EdtNome: TEdit;
    EdtSenha: TEdit;
    GrpConfirma: TPanel;
    GrpLogin: TPanel;
    GrpNome: TPanel;
    GrpSenha: TPanel;
    LblConfirma: TLabel;
    LblErro: TLabel;
    LblLogin: TLabel;
    LblMarca: TLabel;
    LblNome: TLabel;
    LblSecao: TLabel;
    LblSenha: TLabel;
    LblSubMarca: TLabel;
    LblSubtitulo: TLabel;
    LblTitulo: TLabel;
    PnlCabecalho: TPanel;
    PnlCartao: TPanel;
    PnlConfirma: TPanel;
    PnlLogin: TPanel;
    PnlLogo: TPanel;
    PnlNome: TPanel;
    PnlSenha: TPanel;
    procedure BtnConexaoClick(Sender: TObject);
    procedure BtnEntrarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    FPrimeiroAcesso: Boolean;
    FTentativas: Integer;
    procedure Entrar;
    procedure CriarAdministrador;
    function LerUltimoLogin: string;
    procedure GravarUltimoLogin(const ALogin: string);
  public
    procedure Preparar;
  end;

{ Mostra a tela de login. Retorna True se o usuário entrou (Sessao preenchida). }
function ExecutarLogin: Boolean;

implementation

uses
  uDM, uConfig, uUsuarios;

{$R *.lfm}

{ TFrmLogin }

procedure TFrmLogin.Preparar;
begin
  try
    GarantirTabelaUsuario;
    FPrimeiroAcesso := not ExisteUsuario;
  except
    on E: Exception do
    begin
      FPrimeiroAcesso := False;
      Avisar('Tabela de usuários', 'Não foi possível criar/ler a tabela "usuario":' +
        LineEnding + E.Message);
    end;
  end;

  LblErro.Caption := '';
  if FPrimeiroAcesso then
  begin
    LblSenha.Caption := Format('Senha (mínimo %d caracteres)', [SENHA_TAMANHO_MINIMO]);
    EdtLogin.Text := 'admin';
  end
  else
  begin
    LblSecao.Caption := 'ACESSO';
    LblTitulo.Caption := 'Entrar';
    LblSubtitulo.Caption := 'Use seu usuário e senha do SICREQ.';
    LblLogin.Caption := 'Usuário';
    BtnEntrar.Caption := 'Entrar';
    GrpNome.Visible := False;
    GrpConfirma.Visible := False;
    ClientHeight := ClientHeight - GrpNome.Height - GrpConfirma.Height;
    EdtLogin.Text := LerUltimoLogin;
  end;
  { por último: os botões trocados copiam o Caption já ajustado }
  AplicarTema(Self);
end;

procedure TFrmLogin.FormShow(Sender: TObject);
begin
  if FPrimeiroAcesso then
    EdtNome.SetFocus
  else if EdtLogin.Text <> '' then
    EdtSenha.SetFocus
  else
    EdtLogin.SetFocus;
end;

function TFrmLogin.LerUltimoLogin: string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(DM.ArquivoIni);
  try
    Result := Ini.ReadString('Sessao', 'UltimoLogin', '');
  finally
    Ini.Free;
  end;
end;

procedure TFrmLogin.GravarUltimoLogin(const ALogin: string);
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(DM.ArquivoIni);
    try
      Ini.WriteString('Sessao', 'UltimoLogin', ALogin);
    finally
      Ini.Free;
    end;
  except
    { pasta sem permissão de escrita: apenas não lembra o login }
  end;
end;

procedure TFrmLogin.Entrar;
var
  Erro: string;
begin
  LblErro.Caption := '';
  if Trim(EdtLogin.Text) = '' then
  begin
    LblErro.Caption := 'Informe o usuário.';
    EdtLogin.SetFocus;
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    if Autenticar(EdtLogin.Text, EdtSenha.Text, Erro) then
    begin
      GravarUltimoLogin(Trim(EdtLogin.Text));
      ModalResult := mrOK;
      Exit;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  { espera crescente a cada erro (máx. 5 s) }
  Inc(FTentativas);
  Sleep(Min(FTentativas * 500, 5000));
  LblErro.Caption := Erro;
  EdtSenha.Text := '';
  EdtSenha.SetFocus;
end;

procedure TFrmLogin.CriarAdministrador;
var
  Erro: string;
begin
  LblErro.Caption := '';
  if Trim(EdtNome.Text) = '' then
  begin
    LblErro.Caption := 'Informe o nome.';
    EdtNome.SetFocus;
    Exit;
  end;
  if (Trim(EdtLogin.Text) = '') or (Pos(' ', Trim(EdtLogin.Text)) > 0) then
  begin
    LblErro.Caption := 'Informe um login sem espaços.';
    EdtLogin.SetFocus;
    Exit;
  end;
  if Length(EdtSenha.Text) < SENHA_TAMANHO_MINIMO then
  begin
    LblErro.Caption := Format('A senha deve ter ao menos %d caracteres.', [SENHA_TAMANHO_MINIMO]);
    EdtSenha.SetFocus;
    Exit;
  end;
  if EdtSenha.Text <> EdtConfirma.Text then
  begin
    LblErro.Caption := 'A confirmação não confere com a senha.';
    EdtConfirma.SetFocus;
    Exit;
  end;
  try
    { outro computador pode ter criado o primeiro usuário enquanto isso }
    if ExisteUsuario then
    begin
      LblErro.Caption := 'Já existe usuário cadastrado. Feche e abra o sistema de novo.';
      Exit;
    end;
    CriarUsuario(EdtNome.Text, EdtLogin.Text, '', EdtSenha.Text, PERFIL_ADMINISTRADOR);
    if Autenticar(EdtLogin.Text, EdtSenha.Text, Erro) then
    begin
      GravarUltimoLogin(Trim(EdtLogin.Text));
      ModalResult := mrOK;
    end
    else
      LblErro.Caption := Erro;
  except
    on E: Exception do
      LblErro.Caption := 'Não foi possível criar o usuário: ' + E.Message;
  end;
end;

procedure TFrmLogin.BtnEntrarClick(Sender: TObject);
begin
  if FPrimeiroAcesso then
    CriarAdministrador
  else
    Entrar;
end;

procedure TFrmLogin.BtnConexaoClick(Sender: TObject);
begin
  if not EditarConfiguracao then
    Exit;
  try
    DM.Conectar;
    GarantirTabelaUsuario;
    Avisar('Conexão', 'Conectado ao banco ' + DM.Config.Banco + '.');
  except
    on E: Exception do
      Avisar('Falha na conexão', E.Message);
  end;
end;

procedure TFrmLogin.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        BtnEntrarClick(nil);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        ModalResult := mrCancel;
      end;
  end;
end;

function ExecutarLogin: Boolean;
var
  F: TFrmLogin;
begin
  EncerrarSessao;
  F := TFrmLogin.Create(nil);
  try
    F.Preparar;
    Result := F.ShowModal = mrOK;
  finally
    F.Free;
  end;
end;

end.
