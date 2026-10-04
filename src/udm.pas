unit uDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, DB, ZConnection, ZDataset;

type
  TConfigBanco = record
    Host: string;
    Porta: Integer;
    Banco: string;
    Usuario: string;
    Senha: string;
    Biblioteca: string;
  end;

  { TDM }

  TDM = class(TDataModule)
    Conexao: TZConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    FConfig: TConfigBanco;
  public
    function ArquivoIni: string;
    procedure CarregarConfig;
    procedure SalvarConfig(const AConfig: TConfigBanco);
    procedure Conectar;
    { Executa um SELECT que devolve um único valor }
    function ValorSQL(const ASQL: string; const AParams: array of Variant): Variant;
    function NovaConsulta(AOwner: TComponent; const ASQL: string): TZReadOnlyQuery;
    { Executa INSERT/UPDATE/DELETE com parâmetros posicionais (:p0, :p1...) }
    procedure ExecutarSQL(const ASQL: string; const AParams: array of Variant);
    property Config: TConfigBanco read FConfig;
  end;

var
  DM: TDM;

implementation

{$R *.lfm}

{ TDM }

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  CarregarConfig;
end;

function TDM.ArquivoIni: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'sicreq.ini';
end;

procedure TDM.CarregarConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ArquivoIni);
  try
    FConfig.Host := Ini.ReadString('Banco', 'Host', 'localhost');
    FConfig.Porta := Ini.ReadInteger('Banco', 'Porta', 3306);
    FConfig.Banco := Ini.ReadString('Banco', 'Banco', 'sicreq3');
    FConfig.Usuario := Ini.ReadString('Banco', 'Usuario', 'root');
    FConfig.Senha := Ini.ReadString('Banco', 'Senha', '');
    {$IFDEF WINDOWS}
    FConfig.Biblioteca := Ini.ReadString('Banco', 'Biblioteca', 'libmysql.dll');
    {$ELSE}
    FConfig.Biblioteca := Ini.ReadString('Banco', 'Biblioteca', 'libmysqlclient.so.21');
    {$ENDIF}
  finally
    Ini.Free;
  end;
end;

procedure TDM.SalvarConfig(const AConfig: TConfigBanco);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ArquivoIni);
  try
    Ini.WriteString('Banco', 'Host', AConfig.Host);
    Ini.WriteInteger('Banco', 'Porta', AConfig.Porta);
    Ini.WriteString('Banco', 'Banco', AConfig.Banco);
    Ini.WriteString('Banco', 'Usuario', AConfig.Usuario);
    Ini.WriteString('Banco', 'Senha', AConfig.Senha);
    Ini.WriteString('Banco', 'Biblioteca', AConfig.Biblioteca);
  finally
    Ini.Free;
  end;
  FConfig := AConfig;
end;

procedure TDM.Conectar;
begin
  Conexao.Connected := False;
  Conexao.Protocol := 'mysql';
  Conexao.HostName := FConfig.Host;
  Conexao.Port := FConfig.Porta;
  Conexao.Database := FConfig.Banco;
  Conexao.User := FConfig.Usuario;
  Conexao.Password := FConfig.Senha;
  Conexao.LibraryLocation := FConfig.Biblioteca;
  Conexao.ClientCodepage := 'utf8mb4';
  Conexao.AutoCommit := True;
  Conexao.Connected := True;
end;

function TDM.NovaConsulta(AOwner: TComponent; const ASQL: string): TZReadOnlyQuery;
begin
  Result := TZReadOnlyQuery.Create(AOwner);
  Result.Connection := Conexao;
  Result.SQL.Text := ASQL;
end;

procedure TDM.ExecutarSQL(const ASQL: string; const AParams: array of Variant);
var
  Q: TZQuery;
  I: Integer;
begin
  Q := TZQuery.Create(nil);
  try
    Q.Connection := Conexao;
    Q.SQL.Text := ASQL;
    for I := 0 to High(AParams) do
      Q.Params[I].Value := AParams[I];
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TDM.ValorSQL(const ASQL: string; const AParams: array of Variant): Variant;
var
  Q: TZReadOnlyQuery;
  I: Integer;
begin
  Q := NovaConsulta(nil, ASQL);
  try
    for I := 0 to High(AParams) do
      Q.Params[I].Value := AParams[I];
    Q.Open;
    if Q.IsEmpty then
      Result := Null
    else
      Result := Q.Fields[0].Value;
  finally
    Q.Free;
  end;
end;

end.
