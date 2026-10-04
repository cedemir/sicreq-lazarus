unit ueditarimagempersonagem;

{ Inclusão/edição de "Imagens do Personagem" (tabela imagempersonagem).
  Tela visual: edite ueditarimagempersonagem.lfm no designer.

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

  { TFrmEditarImagempersonagem }

  TFrmEditarImagempersonagem = class(TForm)
    BtnArq_imagem_descricao: TButton;
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    BtnVer_imagem_descricao: TButton;
    DsRegistro: TDataSource;
    Edt_imagem_codigo: TDBEdit;
    Edt_imagem_descricao: TDBEdit;
    Lbl_imagem_codigo: TLabel;
    Lbl_imagem_descricao: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_imagem_codigo: TPanel;
    Pnl_imagem_descricao: TPanel;
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
  RegistrarEdicao('imagempersonagem', TFrmEditarImagempersonagem);

end.
