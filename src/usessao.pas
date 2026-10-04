unit uSessao;

{ Usuários, senhas e sessão.

  Senhas: PBKDF2-HMAC-SHA1 com sal aleatório de 16 bytes e 20.000
  iterações (unidades sha1/hmac do próprio FPC). O banco guarda somente
  'pbkdf2-sha1$<iteracoes>$<sal hex>$<hash hex>' - nunca a senha. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, sha1, hmac, ZDataset;

const
  PERFIL_ADMINISTRADOR = 1;
  PERFIL_OPERADOR = 2;
  PERFIL_CONSULTA = 3;

  SENHA_TAMANHO_MINIMO = 6;

  SQL_PERFIL =
    'SELECT 1 AS codigo, ''ADMINISTRADOR'' AS descricao UNION ALL ' +
    'SELECT 2, ''OPERADOR'' UNION ALL SELECT 3, ''CONSULTA''';

type
  TUsuarioSessao = record
    Codigo: Int64;
    Nome: string;
    Login: string;
    Perfil: Integer;
  end;

var
  Sessao: TUsuarioSessao;

{ Cria a tabela "usuario" se ela ainda não existir }
procedure GarantirTabelaUsuario;
function ExisteUsuario: Boolean;

function GerarHashSenha(const ASenha: string): string;
function ConferirSenha(const ASenha, AHashGravado: string): Boolean;

{ Valida login/senha; em caso de sucesso preenche Sessao }
function Autenticar(const ALogin, ASenha: string; out AErro: string): Boolean;
procedure EncerrarSessao;

function NomePerfil(APerfil: Integer): string;
function EhAdministrador: Boolean;
{ Administrador e Operador podem incluir/alterar/excluir no acervo }
function PodeEditar: Boolean;

{ Quantos administradores ativos existem, sem contar AIgnorar (0 = nenhum) }
function AdministradoresAtivos(AIgnorar: Int64): Integer;

implementation

uses
  uDM;

const
  ITERACOES = 20000;
  PREFIXO = 'pbkdf2-sha1';

procedure GarantirTabelaUsuario;
begin
  DM.ExecutarSQL(
    'CREATE TABLE IF NOT EXISTS usuario (' +
    '  usuario_codigo INT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    '  usuario_nome VARCHAR(80) NOT NULL,' +
    '  usuario_login VARCHAR(40) NOT NULL,' +
    '  usuario_email VARCHAR(120) DEFAULT NULL,' +
    '  usuario_senha VARCHAR(200) NOT NULL,' +
    '  usuario_perfil SMALLINT NOT NULL DEFAULT 2,' +
    '  usuario_ativo TINYINT(1) NOT NULL DEFAULT 1,' +
    '  usuario_ultimo_acesso DATETIME DEFAULT NULL,' +
    '  usuario_criado_em TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,' +
    '  PRIMARY KEY (usuario_codigo),' +
    '  UNIQUE KEY usuario_login_unique (usuario_login)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci', []);
end;

function ExisteUsuario: Boolean;
begin
  Result := DM.ValorSQL('SELECT COUNT(*) FROM usuario', []) > 0;
end;

{ ---------------- hash ---------------- }

function BytesParaHex(const ABytes: string): string;
const
  DIG: array[0..15] of Char = '0123456789abcdef';
var
  I: Integer;
begin
  SetLength(Result, Length(ABytes) * 2);
  for I := 1 to Length(ABytes) do
  begin
    Result[I * 2 - 1] := DIG[Ord(ABytes[I]) shr 4];
    Result[I * 2] := DIG[Ord(ABytes[I]) and 15];
  end;
end;

function HexParaBytes(const AHex: string): string;
var
  I: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for I := 1 to Length(Result) do
    Result[I] := Chr(StrToIntDef('$' + Copy(AHex, I * 2 - 1, 2), 0));
end;

function DigestParaStr(const D: TSHA1Digest): string;
begin
  SetString(Result, PChar(@D[0]), SizeOf(D));
end;

{ PBKDF2 (RFC 2898) com HMAC-SHA1, um bloco de 20 bytes }
function PBKDF2(const ASenha, ASal: string; AIteracoes: Integer): string;
var
  U, T: TSHA1Digest;
  I, J: Integer;
begin
  U := HMACSHA1Digest(ASenha, ASal + #0#0#0#1);
  T := U;
  for I := 2 to AIteracoes do
  begin
    U := HMACSHA1Digest(ASenha, DigestParaStr(U));
    for J := 0 to High(T) do
      T[J] := T[J] xor U[J];
  end;
  Result := DigestParaStr(T);
end;

function GerarSal: string;
var
  I: Integer;
  F: TFileStream;
begin
  SetLength(Result, 16);
  {$IFDEF UNIX}
  if FileExists('/dev/urandom') then
  begin
    F := TFileStream.Create('/dev/urandom', fmOpenRead or fmShareDenyNone);
    try
      F.ReadBuffer(Result[1], 16);
      Exit;
    finally
      F.Free;
    end;
  end;
  {$ENDIF}
  for I := 1 to 16 do
    Result[I] := Chr(Random(256));
end;

function GerarHashSenha(const ASenha: string): string;
var
  Sal: string;
begin
  Sal := GerarSal;
  Result := Format('%s$%d$%s$%s', [PREFIXO, ITERACOES, BytesParaHex(Sal),
    BytesParaHex(PBKDF2(ASenha, Sal, ITERACOES))]);
end;

function ConferirSenha(const ASenha, AHashGravado: string): Boolean;
var
  Partes: TStringArray;
  Iter, I: Integer;
  Calculado, Gravado: string;
  Dif: Byte;
begin
  Result := False;
  Partes := AHashGravado.Split('$');
  if (Length(Partes) <> 4) or (Partes[0] <> PREFIXO) then
    Exit;
  Iter := StrToIntDef(Partes[1], 0);
  if Iter < 1 then
    Exit;
  Calculado := PBKDF2(ASenha, HexParaBytes(Partes[2]), Iter);
  Gravado := HexParaBytes(Partes[3]);
  if Length(Calculado) <> Length(Gravado) then
    Exit;
  { comparação em tempo constante }
  Dif := 0;
  for I := 1 to Length(Calculado) do
    Dif := Dif or (Ord(Calculado[I]) xor Ord(Gravado[I]));
  Result := Dif = 0;
end;

{ ---------------- sessão ---------------- }

function Autenticar(const ALogin, ASenha: string; out AErro: string): Boolean;
var
  Q: TZReadOnlyQuery;
begin
  Result := False;
  AErro := 'Usuário ou senha inválidos.';
  Q := DM.NovaConsulta(nil,
    'SELECT usuario_codigo, usuario_nome, usuario_login, usuario_senha, ' +
    'usuario_perfil, usuario_ativo FROM usuario WHERE usuario_login = :p0');
  try
    Q.Params[0].AsString := Trim(ALogin);
    Q.Open;
    { a senha é conferida mesmo sem usuário, para o tempo de resposta não
      revelar se o login existe }
    if Q.IsEmpty then
    begin
      ConferirSenha(ASenha, GerarHashSenha('x'));
      Exit;
    end;
    if not ConferirSenha(ASenha, Q.FieldByName('usuario_senha').AsString) then
      Exit;
    if Q.FieldByName('usuario_ativo').AsInteger <> 1 then
    begin
      AErro := 'Este usuário está desativado. Procure o administrador.';
      Exit;
    end;
    Sessao.Codigo := Q.FieldByName('usuario_codigo').AsLargeInt;
    Sessao.Nome := Q.FieldByName('usuario_nome').AsString;
    Sessao.Login := Q.FieldByName('usuario_login').AsString;
    Sessao.Perfil := Q.FieldByName('usuario_perfil').AsInteger;
  finally
    Q.Free;
  end;
  DM.ExecutarSQL('UPDATE usuario SET usuario_ultimo_acesso = NOW() WHERE usuario_codigo = :p0',
    [Sessao.Codigo]);
  AErro := '';
  Result := True;
end;

procedure EncerrarSessao;
begin
  Sessao.Codigo := 0;
  Sessao.Nome := '';
  Sessao.Login := '';
  Sessao.Perfil := 0;
end;

function NomePerfil(APerfil: Integer): string;
begin
  case APerfil of
    PERFIL_ADMINISTRADOR: Result := 'administrador';
    PERFIL_OPERADOR: Result := 'operador';
    PERFIL_CONSULTA: Result := 'consulta';
  else
    Result := '';
  end;
end;

function EhAdministrador: Boolean;
begin
  Result := Sessao.Perfil = PERFIL_ADMINISTRADOR;
end;

function PodeEditar: Boolean;
begin
  Result := Sessao.Perfil in [PERFIL_ADMINISTRADOR, PERFIL_OPERADOR];
end;

function AdministradoresAtivos(AIgnorar: Int64): Integer;
begin
  Result := DM.ValorSQL('SELECT COUNT(*) FROM usuario WHERE usuario_perfil = 1 ' +
    'AND usuario_ativo = 1 AND usuario_codigo <> :p0', [AIgnorar]);
end;

initialization
  Randomize;
  EncerrarSessao;

end.
