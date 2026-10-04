unit urellistagem;

{ Modelo da listagem impressa pelo botão "Imprimir" das páginas de cadastro.
  Cabeçalho, resumo e rodapé são desenhados aqui; as colunas (BandaColunas /
  BandaDetalhe) são criadas em uRelatorios a partir do Grid da tela.
  Relatório visual: edite urellistagem.lfm no designer (paleta Fortes Report).
  O formulário não é mostrado; serve só de "folha" para o TRLReport.
  O SQL é definido em uRelatorios (não renomeie RLReport1). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, DB, RLReport, RLPDFFilter, ZDataset;

type

  { TFrmRelListagem }

  TFrmRelListagem = class(TForm)
    BandaCabecalho: TRLBand;
    BandaColunas: TRLBand;
    BandaDetalhe: TRLBand;
    BandaResumo: TRLBand;
    BandaRodape: TRLBand;
    DsRel: TDataSource;
    InfoData: TRLSystemInfo;
    InfoPagina: TRLSystemInfo;
    InfoTotal: TRLSystemInfo;
    LblRodape: TRLLabel;
    LblSistema: TRLLabel;
    LblSubtitulo: TRLLabel;
    LblTitulo: TRLLabel;
    RLPDFFilter1: TRLPDFFilter;
    RLReport1: TRLReport;
  end;

implementation

{$R *.lfm}

end.
