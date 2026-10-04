unit uRelatorios;

{ Relatórios com Fortes Report CE.

  Cada relatório é um formulário visual em src/relatorios (TRLReport
  desenhado no designer, com bandas, grupos e campos). Aqui ficam só o
  SQL e a chamada da pré-visualização:

    urelTitulosEditora, urelAcervo, urelHistorias,
    urelPersonagensUniverso, urelCriadores   QryRel + RLReport1 (agrupados)
    urelFichaTitulo                          QryTitulo + QryItens (ficha)
    urelListagem                             modelo do botão "Imprimir"
                                             (as colunas vêm do Grid da tela)

  A pré-visualização do Fortes imprime e salva em PDF (TRLPDFFilter). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Forms, Controls, Graphics, DB, RLReport, RLTypes,
  ZDataset, uDefinicoes;

{ Listagem do botão "Imprimir": dataset da tela + colunas do Grid }
procedure ImprimirListagem(const ATitulo, ASubtitulo: string;
  ADataSet: TDataSet; const AColunas: TColunasDef);

procedure RelTitulosPorEditora;
procedure RelAcervoPorTitulo;
procedure RelHistorias;
procedure RelPersonagensPorUniverso;
procedure RelCriadores;
{ Ficha de um título (dados, exemplares e histórias) }
procedure RelFichaTitulo(const ATituloCodigo: Variant);

implementation

uses
  uDM, uTema, urellistagem, ureltituloseditora, urelacervo, urelhistorias,
  urelpersonagensuniverso, urelcriadores, urelfichatitulo;

const
  LARGURA_RETRATO = 718;   // A4 retrato, margens de 10 mm (pixels a 96 dpi)
  LARGURA_PAISAGEM = 1047; // A4 paisagem

function Relatorio(AForm: TForm): TRLReport;
begin
  Result := AForm.FindComponent('RLReport1') as TRLReport;
  if Result = nil then
    raise Exception.CreateFmt('O relatório %s não tem o componente RLReport1.', [AForm.ClassName]);
end;

function Consulta(AForm: TForm; const ANome, ASQL: string): TZReadOnlyQuery;
begin
  Result := AForm.FindComponent(ANome) as TZReadOnlyQuery;
  if Result = nil then
    raise Exception.CreateFmt('O relatório %s não tem o componente %s.', [AForm.ClassName, ANome]);
  Result.Close;
  Result.Connection := DM.Conexao;
  Result.SQL.Text := ASQL;
end;

{ Relatório com uma consulta (QryRel): abre e mostra a pré-visualização }
procedure RelatorioSimples(AClasse: TFormClass; const ASQL: string);
var
  F: TForm;
  Q: TZReadOnlyQuery;
begin
  Screen.Cursor := crHourGlass;
  F := AClasse.Create(nil);
  try
    Q := Consulta(F, 'QryRel', ASQL);
    Q.Open;
    Screen.Cursor := crDefault;
    if Q.IsEmpty then
    begin
      Avisar('Relatório', 'Não há dados para este relatório.');
      Exit;
    end;
    Relatorio(F).PreviewModal;
  finally
    Screen.Cursor := crDefault;
    F.Free;
  end;
end;

{ ------------------------------------------------------------------ }

procedure ImprimirListagem(const ATitulo, ASubtitulo: string;
  ADataSet: TDataSet; const AColunas: TColunasDef);
var
  F: TFrmRelListagem;
  Rel: TRLReport;
  I, X, W, Total, Largura: Integer;
  Escala: Double;
  Lbl: TRLLabel;
  Txt: TRLDBText;
begin
  F := TFrmRelListagem.Create(nil);
  try
    Rel := Relatorio(F);
    F.DsRel.DataSet := ADataSet;
    Rel.Title := ATitulo;
    F.LblTitulo.Caption := ATitulo;
    F.LblSubtitulo.Caption := ASubtitulo;
    F.LblSubtitulo.Visible := ASubtitulo <> '';

    { orientação conforme a soma das colunas }
    Total := 0;
    for I := 0 to High(AColunas) do
      Inc(Total, AColunas[I].Largura);
    if Total > LARGURA_RETRATO * 1.15 then
    begin
      Rel.PageSetup.Orientation := poLandscape;
      Largura := LARGURA_PAISAGEM;
    end
    else
      Largura := LARGURA_RETRATO;
    if Total > 0 then
      Escala := Largura / Total
    else
      Escala := 1;
    if Escala > 1.3 then
      Escala := 1.3;

    { colunas: títulos em BandaColunas, campos em BandaDetalhe (mesma
      fonte dos componentes de exemplo do modelo, se houver) }
    X := 0;
    for I := 0 to High(AColunas) do
    begin
      W := Round(AColunas[I].Largura * Escala);
      Lbl := TRLLabel.Create(F);
      Lbl.Parent := F.BandaColunas;
      Lbl.AutoSize := False;
      Lbl.SetBounds(X, 4, W - 4, 16);
      Lbl.Caption := AColunas[I].Titulo;
      Lbl.Font.Style := [fsBold];

      Txt := TRLDBText.Create(F);
      Txt.Parent := F.BandaDetalhe;
      Txt.AutoSize := False;
      Txt.SetBounds(X, 1, W - 4, 16);
      Txt.DataSource := F.DsRel;
      Txt.DataField := AColunas[I].Campo;
      if AColunas[I].Estilo in [ecDestaque, ecNumero] then
        Txt.Font.Style := [fsBold];
      Inc(X, W);
    end;

    ADataSet.First;
    Rel.PreviewModal;
  finally
    F.Free;
  end;
end;

procedure RelTitulosPorEditora;
begin
  RelatorioSimples(TFrmRelTitulosEditora,
    'SELECT e.editora_descricao, t.titulo_codigo, t.titulo_descricao, ' +
    'tt.tipotitulo_descricao, s.situacao_descricao, t.titulo_origem, ' +
    '(SELECT COUNT(*) FROM exemplar x WHERE x.titulo_codigo = t.titulo_codigo) AS qtd ' +
    'FROM titulo t ' +
    'JOIN editora e ON e.editora_codigo = t.editora_codigo ' +
    'LEFT JOIN tipo_titulo tt ON tt.tipotitulo_codigo = t.tipotitulo_codigo ' +
    'LEFT JOIN situacao_titulo s ON s.situacao_codigo = t.situacao_codigo ' +
    'ORDER BY e.editora_descricao, t.titulo_descricao');
end;

procedure RelAcervoPorTitulo;
begin
  RelatorioSimples(TFrmRelAcervo,
    'SELECT CONCAT(t.titulo_descricao, '' ('', e.editora_descricao, '')'') AS titulo_nome, ' +
    'x.exemplar_codigo, x.exemplar_subtitulo, x.exemplar_data, tm.tamanho_descricao, ' +
    'ar.armazenagem_descricao, x.exemplar_numeropagina, ' +
    CASE_SITUACAO_EXEMPLAR + ' AS situacao_descricao ' +
    'FROM exemplar x ' +
    'JOIN titulo t ON t.titulo_codigo = x.titulo_codigo ' +
    'JOIN editora e ON e.editora_codigo = t.editora_codigo ' +
    'LEFT JOIN tamanho tm ON tm.tamanho_codigo = x.tamanho_codigo ' +
    'LEFT JOIN armazenagem ar ON ar.armazenagem_codigo = x.armazenagem_codigo ' +
    'ORDER BY t.titulo_descricao, t.titulo_codigo, x.exemplar_codigo');
end;

procedure RelHistorias;
begin
  RelatorioSimples(TFrmRelHistorias,
    'SELECT CONCAT(t.titulo_descricao, '' - nº '', h.exemplar_codigo) AS edicao, ' +
    'h.historia_numero, h.historia_titulo, h.historia_original, ' +
    '(SELECT GROUP_CONCAT(a.artista_nome ORDER BY a.artista_nome SEPARATOR '', '') ' +
    '   FROM artista_historia ah JOIN artista a ON a.artista_codigo = ah.artista_codigo ' +
    '  WHERE ah.titulo_codigo = h.titulo_codigo AND ah.exemplar_codigo = h.exemplar_codigo ' +
    '    AND ah.historia_codigo = h.historia_numero) AS artistas, ' +
    '(SELECT GROUP_CONCAT(p.personagem_descricao ORDER BY p.personagem_descricao SEPARATOR '', '') ' +
    '   FROM historiapersonagem hp JOIN personagem p ON p.personagem_codigo = hp.personagem_codigo ' +
    '  WHERE hp.titulo_codigo = h.titulo_codigo AND hp.exemplar_codigo = h.exemplar_codigo ' +
    '    AND hp.historia_codigo = h.historia_numero) AS personagens ' +
    'FROM historia h JOIN titulo t ON t.titulo_codigo = h.titulo_codigo ' +
    'ORDER BY t.titulo_descricao, h.titulo_codigo, h.exemplar_codigo, h.historia_numero');
end;

procedure RelPersonagensPorUniverso;
begin
  RelatorioSimples(TFrmRelPersonagensUniverso,
    'SELECT u.universo_descricao, p.personagem_codigo, p.personagem_descricao, ' +
    'p.personagem_origem FROM personagem p ' +
    'JOIN universo u ON u.universo_codigo = p.universo_codigo ' +
    'ORDER BY u.universo_descricao, p.personagem_descricao');
end;

procedure RelCriadores;
begin
  RelatorioSimples(TFrmRelCriadores,
    'SELECT a.artista_nome, p.personagem_descricao, u.universo_descricao ' +
    'FROM personagem_criador pc ' +
    'JOIN artista a ON a.artista_codigo = pc.artista_codigo ' +
    'JOIN personagem p ON p.personagem_codigo = pc.personagem_codigo ' +
    'LEFT JOIN universo u ON u.universo_codigo = p.universo_codigo ' +
    'ORDER BY a.artista_nome, p.personagem_descricao');
end;

procedure RelFichaTitulo(const ATituloCodigo: Variant);
var
  F: TFrmRelFichaTitulo;
  QT, QI: TZReadOnlyQuery;
begin
  if VarIsNull(ATituloCodigo) then
    Exit;
  Screen.Cursor := crHourGlass;
  F := TFrmRelFichaTitulo.Create(nil);
  try
    QT := Consulta(F, 'QryTitulo',
      'SELECT t.titulo_codigo, t.titulo_descricao, e.editora_descricao, ' +
      'tt.tipotitulo_descricao, s.situacao_descricao, t.titulo_origem, t.titulo_periodicidade, ' +
      '(SELECT COUNT(*) FROM exemplar x WHERE x.titulo_codigo = t.titulo_codigo) AS qtd_exemplares, ' +
      '(SELECT COUNT(*) FROM historia h WHERE h.titulo_codigo = t.titulo_codigo) AS qtd_historias ' +
      'FROM titulo t ' +
      'LEFT JOIN editora e ON e.editora_codigo = t.editora_codigo ' +
      'LEFT JOIN tipo_titulo tt ON tt.tipotitulo_codigo = t.tipotitulo_codigo ' +
      'LEFT JOIN situacao_titulo s ON s.situacao_codigo = t.situacao_codigo ' +
      'WHERE t.titulo_codigo = :p0');
    QT.Params[0].Value := ATituloCodigo;
    QT.Open;

    { uma linha por história; exemplar sem histórias aparece com o aviso }
    QI := Consulta(F, 'QryItens',
      'SELECT x.exemplar_codigo, x.exemplar_subtitulo, x.exemplar_data, ' +
      'x.exemplar_numeropagina, tm.tamanho_descricao, ' +
      CASE_SITUACAO_EXEMPLAR + ' AS situacao_descricao, ' +
      'h.historia_numero, COALESCE(h.historia_titulo, ''(sem histórias cadastradas)'') AS historia_titulo, ' +
      'h.historia_original, ' +
      '(SELECT GROUP_CONCAT(a.artista_nome ORDER BY a.artista_nome SEPARATOR '', '') ' +
      '   FROM artista_historia ah JOIN artista a ON a.artista_codigo = ah.artista_codigo ' +
      '  WHERE ah.titulo_codigo = h.titulo_codigo AND ah.exemplar_codigo = h.exemplar_codigo ' +
      '    AND ah.historia_codigo = h.historia_numero) AS artistas, ' +
      '(SELECT GROUP_CONCAT(p.personagem_descricao ORDER BY p.personagem_descricao SEPARATOR '', '') ' +
      '   FROM historiapersonagem hp JOIN personagem p ON p.personagem_codigo = hp.personagem_codigo ' +
      '  WHERE hp.titulo_codigo = h.titulo_codigo AND hp.exemplar_codigo = h.exemplar_codigo ' +
      '    AND hp.historia_codigo = h.historia_numero) AS personagens ' +
      'FROM exemplar x ' +
      'LEFT JOIN historia h ON h.titulo_codigo = x.titulo_codigo AND h.exemplar_codigo = x.exemplar_codigo ' +
      'LEFT JOIN tamanho tm ON tm.tamanho_codigo = x.tamanho_codigo ' +
      'WHERE x.titulo_codigo = :p0 ' +
      'ORDER BY x.exemplar_codigo, h.historia_numero');
    QI.Params[0].Value := ATituloCodigo;
    QI.Open;
    Screen.Cursor := crDefault;

    if QT.IsEmpty then
    begin
      Avisar('Ficha do título', 'Título não encontrado.');
      Exit;
    end;
    if QI.IsEmpty then
    begin
      Avisar('Ficha do título', 'Este título ainda não tem exemplares cadastrados.');
      Exit;
    end;
    Relatorio(F).PreviewModal;
  finally
    Screen.Cursor := crDefault;
    F.Free;
  end;
end;

end.
