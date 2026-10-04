unit uMinhaSenha;

{ "Alterar minha senha" do usuário logado.
  Formulário visual: uminhasenha.lfm (tema aplicado por AplicarTema). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Forms, Controls, StdCtrls, ExtCtrls, LCLType,
  LazUTF8, uTema, uTemaForm, uSessao;

type

  { TFrmMinhaSenha }

  TFrmMinhaSenha = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    EdtAtual: TEdit;
    EdtConfirma: TEdit;
    EdtNova: TEdit;
    LblAtual: TLabel;
    LblConfirma: TLabel;
    LblErro: TLabel;
    LblNova: TLabel;
    LblSecao: TLabel;
    LblSubtitulo: TLabel;
    LblTitulo: TLabel;
    PnlAtual: TPanel;
    PnlConfirma: TPanel;
    PnlLinha: TPanel;
    PnlNova: TPanel;
    PnlRodape: TPanel;
    procedure BtnSalvarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

{ Mostra o diálogo; avisa quando a senha foi trocada }
procedure AlterarMinhaSenha;

implementation

uses
  uDM;

{$R *.lfm}

procedure TFrmMinhaSenha.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
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

procedure TFrmMinhaSenha.BtnSalvarClick(Sender: TObject);
var
  Hash: Variant;
begin
  Hash := DM.ValorSQL('SELECT usuario_senha FROM usuario WHERE usuario_codigo = :p0',
    [Sessao.Codigo]);
  if VarIsNull(Hash) or not ConferirSenha(EdtAtual.Text, VarToStr(Hash)) then
  begin
    LblErro.Caption := 'A senha atual está incorreta.';
    EdtAtual.SetFocus;
    Exit;
  end;
  if UTF8Length(EdtNova.Text) < SENHA_TAMANHO_MINIMO then
  begin
    LblErro.Caption := Format('A nova senha deve ter ao menos %d caracteres.', [SENHA_TAMANHO_MINIMO]);
    EdtNova.SetFocus;
    Exit;
  end;
  if EdtNova.Text <> EdtConfirma.Text then
  begin
    LblErro.Caption := 'A confirmação não confere com a nova senha.';
    EdtConfirma.SetFocus;
    Exit;
  end;
  DM.ExecutarSQL('UPDATE usuario SET usuario_senha = :p0 WHERE usuario_codigo = :p1',
    [GerarHashSenha(EdtNova.Text), Sessao.Codigo]);
  ModalResult := mrOK;
end;

procedure AlterarMinhaSenha;
var
  F: TFrmMinhaSenha;
begin
  F := TFrmMinhaSenha.Create(nil);
  try
    F.LblSubtitulo.Caption := Sessao.Nome + ' (' + Sessao.Login + ')';
    AplicarTema(F);
    if F.ShowModal = mrOK then
      Avisar('Senha alterada', 'Sua senha foi alterada com sucesso.');
  finally
    F.Free;
  end;
end;

end.
