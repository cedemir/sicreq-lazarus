unit urelcriadores;

{ Relatório "Criadores de Personagens" (agrupado por artista_nome).
  Relatório visual: edite urelcriadores.lfm no designer (paleta Fortes Report).
  O formulário não é mostrado; serve só de "folha" para o TRLReport.
  O SQL é definido em uRelatorios (não renomeie RLReport1, QryRel). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DB, RLReport, RLPDFFilter, ZDataset;

type

  { TFrmRelCriadores }

  TFrmRelCriadores = class(TForm)
    BandaCabecalho: TRLBand;
    BandaColunas: TRLBand;
    BandaDetalhe: TRLBand;
    BandaGrupo: TRLBand;
    BandaResumo: TRLBand;
    BandaRodape: TRLBand;
    BandaTotalGrupo: TRLBand;
    DBCol1: TRLDBText;
    DBCol2: TRLDBText;
    DBGrupo: TRLDBText;
    DBTotalGrupo: TRLDBResult;
    DsRel: TDataSource;
    Grupo: TRLGroup;
    InfoData: TRLSystemInfo;
    InfoPagina: TRLSystemInfo;
    InfoTotal: TRLSystemInfo;
    LblCol1: TRLLabel;
    LblCol2: TRLLabel;
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
