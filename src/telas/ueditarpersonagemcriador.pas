unit ueditarpersonagemcriador;

{ Inclusão/edição de "Criadores de Personagens" (tabela personagem_criador).
  Tela visual: edite ueditarpersonagemcriador.lfm no designer.

  Não há código aqui: uEdicao adota os componentes pelo nome. Cada campo
  da tabela tem Lbl_<campo> e Edt_<campo> (TDBEdit, TDBMemo, TDBDateEdit
  ou TDBLookupComboBox ligado a DsRegistro/DataField); caixas de texto
  ficam dentro de Pnl_<campo> (Tag 10). Campos de imagem têm
  BtnArq_<campo> e BtnVer_<campo>. Não renomeie esses componentes nem
  QryRegistro, DsRegistro, BtnSalvar, BtnCancelar, LblTitulo, LblTrilha.
  Os TDBLookupComboBox viram a combo escura ao abrir (itens vêm de
  uDefinicoes). Obrigatórios, numeração automática e valores padrão também
  ficam em uDefinicoes. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, DBCtrls, DBExtCtrls,
  DB, ZDataset;

type

  { TFrmEditarPersonagemCriador }

  TFrmEditarPersonagemCriador = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    DsRegistro: TDataSource;
    Edt_artista_codigo: TDBLookupComboBox;
    Edt_personagem_codigo: TDBLookupComboBox;
    Lbl_artista_codigo: TLabel;
    Lbl_personagem_codigo: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    PnlCampos: TPanel;
    PnlDivisa: TPanel;
    PnlLinha: TPanel;
    PnlRodape: TPanel;
    PnlTopo: TPanel;
    QryRegistro: TZQuery;
  end;

implementation

uses
  uTelas;

{$R *.lfm}

initialization
  RegistrarEdicao('personagem_criador', TFrmEditarPersonagemCriador);

end.
