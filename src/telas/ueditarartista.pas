unit ueditarartista;

{ Inclusão/edição de "Artistas" (tabela artista).
  Tela visual: edite ueditarartista.lfm no designer.

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

  { TFrmEditarArtista }

  TFrmEditarArtista = class(TForm)
    BtnArq_artista_foto: TButton;
    BtnCancelar: TButton;
    BtnSalvar: TButton;
    BtnVer_artista_foto: TButton;
    DsRegistro: TDataSource;
    Edt_artista_codigo: TDBEdit;
    Edt_artista_foto: TDBEdit;
    Edt_artista_historico: TDBMemo;
    Edt_artista_nome: TDBEdit;
    Lbl_artista_codigo: TLabel;
    Lbl_artista_foto: TLabel;
    Lbl_artista_historico: TLabel;
    Lbl_artista_nome: TLabel;
    LblDica: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    Pnl_artista_codigo: TPanel;
    Pnl_artista_foto: TPanel;
    Pnl_artista_historico: TPanel;
    Pnl_artista_nome: TPanel;
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
  RegistrarEdicao('artista', TFrmEditarArtista);

end.
