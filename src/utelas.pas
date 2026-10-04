unit uTelas;

{ Registro das telas visuais (.lfm) de cada tabela.

  Cada unit em src/telas registra, na sua seção initialization:
    - a listagem (TFrame)  -> RegistrarLista('titulo', TFraListaTitulo)
    - a edição   (TForm)   -> RegistrarEdicao('titulo', TFrmEditaTitulo)

  uCadastro e uEdicao pedem a classe pelo nome da tabela e "adotam" os
  componentes pelo nome (Grid, QryLista, EdtBusca, QryRegistro, Edt_<campo>...).
  As telas em si não têm código. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

procedure RegistrarLista(const ATabela: string; AClasse: TCustomFrameClass);
procedure RegistrarEdicao(const ATabela: string; AClasse: TCustomFormClass);
function ClasseLista(const ATabela: string): TCustomFrameClass;
function ClasseEdicao(const ATabela: string): TCustomFormClass;

implementation

var
  FListas, FEdicoes: TStringList;

procedure RegistrarLista(const ATabela: string; AClasse: TCustomFrameClass);
begin
  FListas.AddObject(ATabela, TObject(Pointer(AClasse)));
end;

procedure RegistrarEdicao(const ATabela: string; AClasse: TCustomFormClass);
begin
  FEdicoes.AddObject(ATabela, TObject(Pointer(AClasse)));
end;

function ClasseLista(const ATabela: string): TCustomFrameClass;
var
  I: Integer;
begin
  I := FListas.IndexOf(ATabela);
  if I < 0 then
    raise Exception.CreateFmt('Tela de listagem não registrada para a tabela "%s".', [ATabela]);
  Result := TCustomFrameClass(Pointer(FListas.Objects[I]));
end;

function ClasseEdicao(const ATabela: string): TCustomFormClass;
var
  I: Integer;
begin
  I := FEdicoes.IndexOf(ATabela);
  if I < 0 then
    raise Exception.CreateFmt('Tela de edição não registrada para a tabela "%s".', [ATabela]);
  Result := TCustomFormClass(Pointer(FEdicoes.Objects[I]));
end;

initialization
  FListas := TStringList.Create;
  FEdicoes := TStringList.Create;

finalization
  FListas.Free;
  FEdicoes.Free;

end.
