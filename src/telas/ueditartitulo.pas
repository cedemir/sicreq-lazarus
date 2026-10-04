unit ueditartitulo;

{ Inclusão/edição de "Títulos" (tabela titulo).
  Tela visual: edite ueditartitulo.lfm no designer.

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

  { TFrmEditarTitulo }

  TFrmEditarTitulo = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    DsRegistro: TDataSource;
    Edt_editora_codigo: TDBLookupComboBox;
    Edt_situacao_codigo: TDBLookupComboBox;
    Edt_tipotitulo_codigo: TDBLookupComboBox;
    Edt_titulo_codigo: TDBEdit;
    Edt_titulo_descricao: TDBEdit;
    Edt_titulo_origem: TDBEdit;
    Edt_titulo_periodicidade: TDBEdit;
    Lbl_editora_codigo: TLabel;
    Lbl_situacao_codigo: TLabel;
    Lbl_tipotitulo_codigo: TLabel;
    Lbl_titulo_codigo: TLabel;
    Lbl_titulo_descricao: TLabel;
    Lbl_titulo_origem: TLabel;
    Lbl_titulo_periodicidade: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_titulo_codigo: TPanel;
    Pnl_titulo_descricao: TPanel;
    Pnl_titulo_origem: TPanel;
    Pnl_titulo_periodicidade: TPanel;
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
  RegistrarEdicao('titulo', TFrmEditarTitulo);

end.
