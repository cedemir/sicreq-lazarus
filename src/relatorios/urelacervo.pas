unit urelacervo;

{ Relatório "Acervo - Exemplares por Título" (agrupado por titulo_nome).
  Relatório visual: edite urelacervo.lfm no designer (paleta Fortes Report).
  O formulário não é mostrado; serve só de "folha" para o TRLReport.
  O SQL é definido em uRelatorios (não renomeie RLReport1, QryRel). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DB, RLReport, RLPDFFilter, ZDataset;

type

  { TFrmRelAcervo }

  TFrmRelAcervo = class(TForm)
    BandaCabecalho: TRLBand;
    BandaColunas: TRLBand;
    BandaDetalhe: TRLBand;
    BandaGrupo: TRLBand;
    BandaResumo: TRLBand;
    BandaRodape: TRLBand;
    BandaTotalGrupo: TRLBand;
    DBCol1: TRLDBText;
    DBCol2: TRLDBText;
    DBCol3: TRLDBText;
    DBCol4: TRLDBText;
    DBCol5: TRLDBText;
    DBCol6: TRLDBText;
    DBCol7: TRLDBText;
    DBGrupo: TRLDBText;
    DBTotalGrupo: TRLDBResult;
    DsRel: TDataSource;
    Grupo: TRLGroup;
    InfoData: TRLSystemInfo;
    InfoPagina: TRLSystemInfo;
    InfoTotal: TRLSystemInfo;
    LblCol1: TRLLabel;
    LblCol2: TRLLabel;
    LblCol3: TRLLabel;
    LblCol4: TRLLabel;
    LblCol5: TRLLabel;
    LblCol6: TRLLabel;
    LblCol7: TRLLabel;
    LblGrupo: TRLLabel;
    LblRodape: TRLLabel;
    LblSistema: TRLLabel;
    LblTitulo: TRLLabel;
    QryRel: TZReadOnlyQuery;
    RLPDFFilter1: TRLPDFFilter;
    RLReport1: TRLReport;
  end;

implementation

{$R *.lfm}

end.
