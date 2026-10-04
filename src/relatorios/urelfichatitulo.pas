unit urelfichatitulo;

{ Ficha de um título: dados do título (DsTitulo) e, por exemplar,
  as histórias com artistas e personagens (DsItens, agrupado por exemplar).
  Relatório visual: edite urelfichatitulo.lfm no designer (paleta Fortes Report).
  O formulário não é mostrado; serve só de "folha" para o TRLReport.
  O SQL é definido em uRelatorios (não renomeie RLReport1, QryTitulo, QryItens). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DB, RLReport, RLPDFFilter, ZDataset;

type

  { TFrmRelFichaTitulo }

  TFrmRelFichaTitulo = class(TForm)
    BandaCabecalho: TRLBand;
    BandaEspaco: TRLBand;
    BandaExemplar: TRLBand;
    BandaHistoria: TRLBand;
    BandaRodape: TRLBand;
    BandaTitulo: TRLBand;
    DBData: TRLDBText;
    DBEditora: TRLDBText;
    DBHist1: TRLDBText;
    DBHist2: TRLDBText;
    DBHist3: TRLDBText;
    DBHist4: TRLDBText;
    DBHist5: TRLDBText;
    DBNumero: TRLDBText;
    DBOrigem: TRLDBText;
    DBPaginas: TRLDBText;
    DBQtdEx: TRLDBText;
    DBQtdHist: TRLDBText;
    DBSituacao: TRLDBText;
    DBSituacaoEx: TRLDBText;
    DBSubtitulo: TRLDBText;
    DBTamanho: TRLDBText;
    DBTipo: TRLDBText;
    DBTitulo: TRLDBText;
    DsItens: TDataSource;
    DsTitulo: TDataSource;
    GrupoExemplar: TRLGroup;
    InfoData: TRLSystemInfo;
    InfoPagina: TRLSystemInfo;
    LblData: TRLLabel;
    LblEditora: TRLLabel;
    LblHist1: TRLLabel;
    LblHist2: TRLLabel;
    LblHist3: TRLLabel;
    LblHist4: TRLLabel;
    LblHist5: TRLLabel;
    LblNumero: TRLLabel;
    LblOrigem: TRLLabel;
    LblPaginas: TRLLabel;
    LblQtdEx: TRLLabel;
    LblQtdHist: TRLLabel;
    LblRodape: TRLLabel;
    LblSistema: TRLLabel;
    LblSituacao: TRLLabel;
    LblSituacaoEx: TRLLabel;
    LblTamanho: TRLLabel;
    LblTipo: TRLLabel;
    LblTitulo: TRLLabel;
    QryItens: TZReadOnlyQuery;
    QryTitulo: TZReadOnlyQuery;
    RLPDFFilter1: TRLPDFFilter;
    RLReport1: TRLReport;
  end;

implementation

{$R *.lfm}

end.
