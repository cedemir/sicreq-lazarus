unit ueditarexemplar;

{ Inclusão/edição de "Exemplares" (tabela exemplar).
  Tela visual: edite ueditarexemplar.lfm no designer.

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

  { TFrmEditarExemplar }

  TFrmEditarExemplar = class(TForm)
    BtnArq_exemplar_capa: TButton;
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    BtnVer_exemplar_capa: TButton;
    DsRegistro: TDataSource;
    Edt_armazenagem_codigo: TDBLookupComboBox;
    Edt_exemplar_capa: TDBEdit;
    Edt_exemplar_codigo: TDBEdit;
    Edt_exemplar_data: TDBDateEdit;
    Edt_exemplar_numeropagina: TDBEdit;
    Edt_exemplar_situacao: TDBLookupComboBox;
    Edt_exemplar_subtitulo: TDBEdit;
    Edt_tamanho_codigo: TDBLookupComboBox;
    Lbl_armazenagem_codigo: TLabel;
    Lbl_exemplar_capa: TLabel;
    Lbl_exemplar_codigo: TLabel;
    Lbl_exemplar_data: TLabel;
    Lbl_exemplar_numeropagina: TLabel;
    Lbl_exemplar_situacao: TLabel;
    Lbl_exemplar_subtitulo: TLabel;
    Lbl_tamanho_codigo: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_exemplar_capa: TPanel;
    Pnl_exemplar_codigo: TPanel;
    Pnl_exemplar_numeropagina: TPanel;
    Pnl_exemplar_subtitulo: TPanel;
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
  RegistrarEdicao('exemplar', TFrmEditarExemplar);

end.
