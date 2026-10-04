unit uConfig;

{ Diálogo de configuração da conexão (gravada em sicreq.ini).
  Formulário visual: uconfig.lfm. O tema escuro (botões arredondados,
  caixas) é aplicado ao abrir por AplicarTema - veja uTemaForm. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs, LCLType,
  uDM, uTema, uTemaForm;

type

  { TFrmConfig }

  TFrmConfig = class(TForm)
    BtnCancelar: TButton;
    BtnProcurar: TButton;
    BtnSalvar: TButton;
    BtnTestar: TButton;
    EdtBanco: TEdit;
    EdtBiblioteca: TEdit;
    EdtHost: TEdit;
    EdtPorta: TEdit;
    EdtSenha: TEdit;
    EdtUsuario: TEdit;
    LblBanco: TLabel;
    LblBiblioteca: TLabel;
    LblHost: TLabel;
    LblPorta: TLabel;
    LblSecao: TLabel;
    LblSenha: TLabel;
    LblSubtitulo: TLabel;
    LblTitulo: TLabel;
    LblUsuario: TLabel;
    PnlBanco: TPanel;
    PnlBiblioteca: TPanel;
    PnlHost: TPanel;
    PnlLinha: TPanel;
    PnlPorta: TPanel;
    PnlRodape: TPanel;
    PnlSenha: TPanel;
    PnlUsuario: TPanel;
    procedure BtnProcurarClick(Sender: TObject);
    procedure BtnTestarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    function LerTela: TConfigBanco;
  public
    procedure Carregar;
    procedure Salvar;
  end;

{ Mostra o diálogo. Retorna True se o usuário salvou. }
function EditarConfiguracao: Boolean;
{ Conecta usando sicreq.ini; em caso de falha oferece o diálogo de
  configuração. Retorna False se o usuário desistir. }
function ConectarComConfiguracao: Boolean;

implementation

{$R *.lfm}

{ TFrmConfig }

procedure TFrmConfig.Carregar;
begin
  EdtHost.Text := DM.Config.Host;
  EdtPorta.Text := IntToStr(DM.Config.Porta);
  EdtBanco.Text := DM.Config.Banco;
  EdtUsuario.Text := DM.Config.Usuario;
  EdtSenha.Text := DM.Config.Senha;
  EdtBiblioteca.Text := DM.Config.Biblioteca;
end;

function TFrmConfig.LerTela: TConfigBanco;
begin
  Result.Host := Trim(EdtHost.Text);
  Result.Porta := StrToIntDef(Trim(EdtPorta.Text), 3306);
  Result.Banco := Trim(EdtBanco.Text);
  Result.Usuario := Trim(EdtUsuario.Text);
  Result.Senha := EdtSenha.Text;
  Result.Biblioteca := Trim(EdtBiblioteca.Text);
end;

procedure TFrmConfig.Salvar;
begin
  DM.SalvarConfig(LerTela);
end;

procedure TFrmConfig.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        ModalResult := mrOK;
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        ModalResult := mrCancel;
      end;
  end;
end;

procedure TFrmConfig.BtnTestarClick(Sender: TObject);
var
  Anterior: TConfigBanco;
begin
  Anterior := DM.Config;
  DM.SalvarConfig(LerTela);
  try
    try
      DM.Conectar;
      Avisar('Conexão realizada', 'Servidor MySQL ' + DM.Conexao.ServerVersionStr + '.');
    except
      on E: Exception do
        Avisar('Falha na conexão', E.Message);
    end;
  finally
    DM.SalvarConfig(Anterior);
  end;
end;

procedure TFrmConfig.BtnProcurarClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Localizar biblioteca cliente do MySQL';
    if Dlg.Execute then
      EdtBiblioteca.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

function EditarConfiguracao: Boolean;
var
  F: TFrmConfig;
begin
  F := TFrmConfig.Create(nil);
  try
    F.Carregar;
    AplicarTema(F);
    Result := F.ShowModal = mrOK;
    if Result then
      F.Salvar;
  finally
    F.Free;
  end;
end;

function ConectarComConfiguracao: Boolean;
begin
  repeat
    try
      DM.Conectar;
      Exit(True);
    except
      on E: Exception do
        Avisar('Não foi possível conectar',
          E.Message + LineEnding + LineEnding + 'Verifique a configuração da conexão.');
    end;
  until not EditarConfiguracao;
  Result := False;
end;

end.
