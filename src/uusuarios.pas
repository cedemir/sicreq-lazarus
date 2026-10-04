unit uUsuarios;

{ Cadastro de usuários (diálogo próprio, por causa da senha).
  Formulário visual: uusuarios.lfm. Ao abrir, AplicarTema (uTemaForm)
  troca os botões pelos arredondados e os TComboBox pelo TCaixaEscolha.

  Regras:
  - login único; senha com no mínimo SENHA_TAMANHO_MINIMO caracteres;
  - na edição, senha em branco mantém a atual;
  - sempre deve restar ao menos um administrador ativo;
  - ninguém exclui nem desativa o próprio usuário. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Math, Forms, Controls, StdCtrls, ExtCtrls,
  Graphics, LCLType, LazUTF8, ZDataset, uDefinicoes, uTema, uTemaForm,
  uEscolha, uSessao;

type

  { TFrmUsuario }

  TFrmUsuario = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    CbAtivo: TComboBox;
    CbPerfil: TComboBox;
    EdtConfirma: TEdit;
    EdtEmail: TEdit;
    EdtLogin: TEdit;
    EdtNome: TEdit;
    EdtSenha: TEdit;
    LblAtivo: TLabel;
    LblConfirma: TLabel;
    LblEmail: TLabel;
    LblErro: TLabel;
    LblLogin: TLabel;
    LblNome: TLabel;
    LblPerfil: TLabel;
    LblSecao: TLabel;
    LblSenha: TLabel;
    LblSubtitulo: TLabel;
    LblTitulo: TLabel;
    PnlConfirma: TPanel;
    PnlEmail: TPanel;
    PnlLinha: TPanel;
    PnlLogin: TPanel;
    PnlNome: TPanel;
    PnlRodape: TPanel;
    PnlSenha: TPanel;
    procedure BtnSalvarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FCodigo: Variant;   // Null = novo
    { combos escuras criadas no lugar de CbPerfil / CbAtivo }
    CmbPerfil, CmbAtivo: TCaixaEscolha;
    procedure Erro(const AMensagem: string; AFoco: TWinControl);
  public
    ChaveGravada: Variant;
    procedure Preparar(const AChave: Variant);
  end;

function EditarUsuario(ADef: TTabelaDef; const AChave: Variant;
  const AFixos: TFiltrosFixos; const ATrilha: string;
  out AChaveGravada: Variant): Boolean;
function ValidarExclusaoUsuario(const AChave: Variant): string;

{ Cria um usuário (usado também no primeiro acesso, na tela de login) }
function CriarUsuario(const ANome, ALogin, AEmail, ASenha: string;
  APerfil: Integer): Int64;

implementation

uses
  uDM;

{$R *.lfm}

function CriarUsuario(const ANome, ALogin, AEmail, ASenha: string;
  APerfil: Integer): Int64;
var
  Email: Variant;
begin
  if Trim(AEmail) = '' then
    Email := Null
  else
    Email := Trim(AEmail);
  DM.ExecutarSQL('INSERT INTO usuario (usuario_nome, usuario_login, usuario_email, ' +
    'usuario_senha, usuario_perfil, usuario_ativo) VALUES (:p0, :p1, :p2, :p3, :p4, 1)',
    [Trim(ANome), Trim(ALogin), Email, GerarHashSenha(ASenha), APerfil]);
  Result := DM.ValorSQL('SELECT LAST_INSERT_ID()', []);
end;

{ TFrmUsuario }

procedure TFrmUsuario.Preparar(const AChave: Variant);
var
  Q: TZReadOnlyQuery;
begin
  FCodigo := AChave;
  ChaveGravada := Null;
  if VarIsNull(AChave) then
  begin
    LblTitulo.Caption := 'Novo usuário';
    LblSubtitulo.Caption := 'Defina o perfil e uma senha inicial.';
    LblSenha.Caption := 'Senha *';
    LblConfirma.Caption := 'Confirmar senha *';
  end
  else
  begin
    LblTitulo.Caption := 'Editar usuário';
    LblSubtitulo.Caption := 'Deixe a senha em branco para manter a atual.';
    LblSenha.Caption := 'Nova senha';
    LblConfirma.Caption := 'Confirmar nova senha';
  end;

  AplicarTema(Self);
  CmbPerfil := TrocarCombo(CbPerfil);
  CmbPerfil.Adicionar('ADMINISTRADOR - tudo, inclusive usuários', PERFIL_ADMINISTRADOR);
  CmbPerfil.Adicionar('OPERADOR - cadastra o acervo', PERFIL_OPERADOR);
  CmbPerfil.Adicionar('CONSULTA - apenas visualiza', PERFIL_CONSULTA);
  CmbAtivo := TrocarCombo(CbAtivo);
  CmbAtivo.Adicionar('ATIVO - pode entrar no sistema', 1);
  CmbAtivo.Adicionar('INATIVO - acesso bloqueado', 0);

  if VarIsNull(AChave) then
  begin
    CmbPerfil.Valor := PERFIL_OPERADOR;
    CmbAtivo.Valor := 1;
    Exit;
  end;

  Q := DM.NovaConsulta(nil, 'SELECT * FROM usuario WHERE usuario_codigo = :p0');
  try
    Q.Params[0].Value := AChave;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('Usuário não encontrado (pode ter sido excluído).');
    EdtNome.Text := Q.FieldByName('usuario_nome').AsString;
    EdtLogin.Text := Q.FieldByName('usuario_login').AsString;
    EdtEmail.Text := Q.FieldByName('usuario_email').AsString;
    CmbPerfil.Valor := Q.FieldByName('usuario_perfil').AsInteger;
    CmbAtivo.Valor := Q.FieldByName('usuario_ativo').AsInteger;
  finally
    Q.Free;
  end;
  { o próprio usuário não muda o próprio perfil nem se desativa }
  if AChave = Sessao.Codigo then
  begin
    CmbPerfil.ReadOnly := True;
    CmbAtivo.ReadOnly := True;
  end;
end;

procedure TFrmUsuario.Erro(const AMensagem: string; AFoco: TWinControl);
begin
  LblErro.Caption := AMensagem;
  if (AFoco <> nil) and AFoco.CanFocus then
    AFoco.SetFocus;
end;

procedure TFrmUsuario.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if EscolhaAberta then
    Exit;
  case Key of
    VK_F2:
      begin
        Key := 0;
        BtnSalvarClick(nil);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        ModalResult := mrCancel;
      end;
  end;
end;

procedure TFrmUsuario.BtnSalvarClick(Sender: TObject);
var
  Codigo: Int64;
  Novo, EraAdminAtivo, SeraAdminAtivo: Boolean;
  Email: Variant;
begin
  Novo := VarIsNull(FCodigo);
  if Novo then
    Codigo := 0
  else
    Codigo := FCodigo;

  if Trim(EdtNome.Text) = '' then
    begin Erro('Informe o nome.', EdtNome); Exit; end;
  if Trim(EdtLogin.Text) = '' then
    begin Erro('Informe o login.', EdtLogin); Exit; end;
  if Pos(' ', Trim(EdtLogin.Text)) > 0 then
    begin Erro('O login não pode ter espaços.', EdtLogin); Exit; end;
  if DM.ValorSQL('SELECT COUNT(*) FROM usuario WHERE usuario_login = :p0 ' +
    'AND usuario_codigo <> :p1', [Trim(EdtLogin.Text), Codigo]) > 0 then
    begin Erro('Já existe um usuário com este login.', EdtLogin); Exit; end;
  if VarIsNull(CmbPerfil.Valor) then
    begin Erro('Escolha o perfil.', CmbPerfil); Exit; end;
  if Novo or (EdtSenha.Text <> '') or (EdtConfirma.Text <> '') then
  begin
    if UTF8Length(EdtSenha.Text) < SENHA_TAMANHO_MINIMO then
      begin Erro(Format('A senha deve ter ao menos %d caracteres.', [SENHA_TAMANHO_MINIMO]), EdtSenha); Exit; end;
    if EdtSenha.Text <> EdtConfirma.Text then
      begin Erro('A confirmação não confere com a senha.', EdtConfirma); Exit; end;
  end;

  { não deixar o sistema sem administrador ativo }
  if not Novo then
  begin
    EraAdminAtivo := DM.ValorSQL('SELECT COUNT(*) FROM usuario WHERE usuario_codigo = :p0 ' +
      'AND usuario_perfil = 1 AND usuario_ativo = 1', [Codigo]) > 0;
    SeraAdminAtivo := (CmbPerfil.Valor = PERFIL_ADMINISTRADOR) and (CmbAtivo.Valor = 1);
    if EraAdminAtivo and not SeraAdminAtivo and (AdministradoresAtivos(Codigo) = 0) then
      begin Erro('Este é o único administrador ativo. Cadastre outro antes de mudar o perfil ou desativá-lo.', CmbPerfil); Exit; end;
  end;

  if Trim(EdtEmail.Text) = '' then
    Email := Null
  else
    Email := Trim(EdtEmail.Text);

  try
    if Novo then
    begin
      Codigo := CriarUsuario(EdtNome.Text, EdtLogin.Text, EdtEmail.Text, EdtSenha.Text,
        CmbPerfil.Valor);
      if CmbAtivo.Valor = 0 then
        DM.ExecutarSQL('UPDATE usuario SET usuario_ativo = 0 WHERE usuario_codigo = :p0', [Codigo]);
    end
    else
    begin
      DM.ExecutarSQL('UPDATE usuario SET usuario_nome = :p0, usuario_login = :p1, ' +
        'usuario_email = :p2, usuario_perfil = :p3, usuario_ativo = :p4 ' +
        'WHERE usuario_codigo = :p5',
        [Trim(EdtNome.Text), Trim(EdtLogin.Text), Email, CmbPerfil.Valor,
         CmbAtivo.Valor, Codigo]);
      if EdtSenha.Text <> '' then
        DM.ExecutarSQL('UPDATE usuario SET usuario_senha = :p0 WHERE usuario_codigo = :p1',
          [GerarHashSenha(EdtSenha.Text), Codigo]);
      { o usuário logado alterou os próprios dados }
      if Codigo = Sessao.Codigo then
      begin
        Sessao.Nome := Trim(EdtNome.Text);
        Sessao.Login := Trim(EdtLogin.Text);
      end;
    end;
  except
    on E: Exception do
      begin Erro('Não foi possível salvar: ' + E.Message, nil); Exit; end;
  end;
  ChaveGravada := Codigo;
  ModalResult := mrOK;
end;

function EditarUsuario(ADef: TTabelaDef; const AChave: Variant;
  const AFixos: TFiltrosFixos; const ATrilha: string;
  out AChaveGravada: Variant): Boolean;
var
  F: TFrmUsuario;
begin
  AChaveGravada := Null;
  if not EhAdministrador then
  begin
    Avisar('Acesso negado', 'Somente administradores gerenciam usuários.');
    Exit(False);
  end;
  F := TFrmUsuario.Create(nil);
  try
    F.Preparar(AChave);
    Result := F.ShowModal = mrOK;
    if Result then
      AChaveGravada := F.ChaveGravada;
  finally
    F.Free;
  end;
end;

function ValidarExclusaoUsuario(const AChave: Variant): string;
begin
  Result := '';
  if not EhAdministrador then
    Exit('Somente administradores gerenciam usuários.');
  if AChave = Sessao.Codigo then
    Exit('Você não pode excluir o próprio usuário.');
  if (DM.ValorSQL('SELECT COUNT(*) FROM usuario WHERE usuario_codigo = :p0 ' +
      'AND usuario_perfil = 1 AND usuario_ativo = 1', [AChave]) > 0) and
     (AdministradoresAtivos(AChave) = 0) then
    Exit('É preciso manter ao menos um administrador ativo.');
end;

initialization
  Definicao('usuario').Editor := @EditarUsuario;
  Definicao('usuario').ValidarExclusao := @ValidarExclusaoUsuario;

end.
