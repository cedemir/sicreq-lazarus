unit ueditartamanho;

{ Inclusão/edição de "Tamanhos / Formatos" (tabela tamanho).
  Tela visual: edite ueditartamanho.lfm no designer.

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

  { TFrmEditarTamanho }

  TFrmEditarTamanho = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    DsRegistro: TDataSource;
    Edt_tamanho_codigo: TDBEdit;
    Edt_tamanho_coluna: TDBEdit;
    Edt_tamanho_descricao: TDBEdit;
    Edt_tamanho_linha: TDBEdit;
    Lbl_tamanho_codigo: TLabel;
    Lbl_tamanho_coluna: TLabel;
    Lbl_tamanho_descricao: TLabel;
    Lbl_tamanho_linha: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_tamanho_codigo: TPanel;
    Pnl_tamanho_coluna: TPanel;
    Pnl_tamanho_descricao: TPanel;
    Pnl_tamanho_linha: TPanel;
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
  RegistrarEdicao('tamanho', TFrmEditarTamanho);

end.
