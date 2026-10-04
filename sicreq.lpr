program sicreq;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  uDM, uTema, uEscolha, uTemaForm, uDefinicoes, uSessao, uConfig, uEdicao,
  uCadastro, uUsuarios, uMinhaSenha, uLogin, uPaginas, uRelatorios, uTelas,
  { relatórios visuais (src/relatorios) }
  urelacervo, urelcriadores, urelfichatitulo, urelhistorias, urellistagem, urelpersonagensuniverso, ureltituloseditora,
  { telas visuais de cada tabela (src/telas) }
  ueditararmazenagem, ueditarartista, ueditarartistahistoria, ueditareditora,
  ueditarexemplar, ueditarhistoria, ueditarhistoriapersonagem,
  ueditarimagempersonagem, ueditarpersonagem, ueditarpersonagemcriador,
  ueditarsituacaotitulo, ueditartamanho, ueditartipotitulo, ueditartitulo,
  ueditaruniverso, ulistaarmazenagem, ulistaartista, ulistaartistahistoria,
  ulistaeditora, ulistaexemplar, ulistahistoria, ulistahistoriapersonagem,
  ulistaimagempersonagem, ulistapersonagem, ulistapersonagemcriador,
  ulistasituacaotitulo, ulistatamanho, ulistatipotitulo, ulistatitulo,
  ulistauniverso, ulistausuario,
  uPrincipal;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'SICREQ';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  if ConectarComConfiguracao and ExecutarLogin then
  begin
    Application.CreateForm(TFrmPrincipal, FrmPrincipal);
    Application.Run;
  end;
end.
