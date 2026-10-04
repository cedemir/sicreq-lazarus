unit ueditartipotitulo;

{ Inclusão/edição de "Tipos de Título" (tabela tipo_titulo).
  Tela visual: edite ueditartipotitulo.lfm no designer.

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

  { TFrmEditarTipoTitulo }

  TFrmEditarTipoTitulo = class(TForm)
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    DsRegistro: TDataSource;
    Edt_tipotitulo_codigo: TDBEdit;
    Edt_tipotitulo_descricao: TDBEdit;
    Lbl_tipotitulo_codigo: TLabel;
    Lbl_tipotitulo_descricao: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_tipotitulo_codigo: TPanel;
    Pnl_tipotitulo_descricao: TPanel;
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
  RegistrarEdicao('tipo_titulo', TFrmEditarTipoTitulo);

end.
