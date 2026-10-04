unit ulistahistoriapersonagem;

{ Listagem de "Personagens da História" (tabela historiapersonagem).
  Tela visual: edite ulistahistoriapersonagem.lfm no designer.

  Não há código aqui: uCadastro.TPaginaCadastro adota os componentes pelo
  nome (Grid, QryLista, EdtBusca, CbFiltro, BtnNovo, BtnImprimir, BtnVoltar,
  LblTrilha, LblContagem, PnlTrilha). Não renomeie esses componentes.
  Colunas do Grid: Tag = estilo (0 normal, 1 negrito, 2 número âmbar,
  3 suave); a coluna com Tag = 100 é a de AÇÕES (botões por linha).
  O tema escuro é aplicado pelo Tag (veja uTemaForm). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, DBGrids, DB, ZDataset;

type

  { TFraListaHistoriapersonagem }

  TFraListaHistoriapersonagem = class(TFrame)
    BtnImprimir: TButton;
    BtnNovo: TButton;
    BtnVoltar: TButton;
    DsLista: TDataSource;
    EdtBusca: TEdit;
    Grid: TDBGrid;
    LblContagem: TLabel;
    LblDescricao: TLabel;
    LblSecao: TLabel;
    LblTitulo: TLabel;
    LblTrilha: TLabel;
    PnlBarra: TPanel;
    PnlBusca: TPanel;
    PnlCabecalho: TPanel;
    PnlCartao: TPanel;
    PnlRodape: TPanel;
    PnlTrilha: TPanel;
    QryLista: TZReadOnlyQuery;
  end;

implementation

uses
  uTelas;

{$R *.lfm}

initialization
  RegistrarLista('historiapersonagem', TFraListaHistoriapersonagem);

end.
