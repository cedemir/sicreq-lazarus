unit ueditarhistoria;

{ Inclusão/edição de "Histórias" (tabela historia).
  Tela visual: edite ueditarhistoria.lfm no designer.

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

  { TFrmEditarHistoria }

  TFrmEditarHistoria = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    DsRegistro: TDataSource;
    Edt_historia_cor: TDBLookupComboBox;
    Edt_historia_numero: TDBEdit;
    Edt_historia_original: TDBEdit;
    Edt_historia_resumo: TDBMemo;
    Edt_historia_titulo: TDBEdit;
    Lbl_historia_cor: TLabel;
    Lbl_historia_numero: TLabel;
    Lbl_historia_original: TLabel;
    Lbl_historia_resumo: TLabel;
    Lbl_historia_titulo: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_historia_numero: TPanel;
    Pnl_historia_original: TPanel;
    Pnl_historia_resumo: TPanel;
    Pnl_historia_titulo: TPanel;
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
  RegistrarEdicao('historia', TFrmEditarHistoria);

end.
