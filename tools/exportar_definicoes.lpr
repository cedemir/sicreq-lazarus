program exportar_definicoes;

{ Exporta os metadados de src/udefinicoes.pas em JSON, para o gerador
  de telas (tools/gerar_telas.py). Programa de console; não usa a LCL.
  Uso: exportar_definicoes > definicoes.json }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Variants, fpjson, uDefinicoes;

const
  TABELAS: array[0..15] of string = (
    'titulo', 'exemplar', 'historia', 'artista_historia', 'historiapersonagem',
    'artista', 'personagem', 'personagem_criador', 'imagempersonagem',
    'editora', 'universo', 'tipo_titulo', 'situacao_titulo', 'tamanho',
    'armazenagem', 'usuario');
  TIPOS: array[TTipoCampo] of string = (
    'texto', 'memo', 'inteiro', 'decimal', 'data', 'lookup', 'imagem');

var
  Raiz, T: TJSONObject;
  Arr: TJSONArray;
  D: TTabelaDef;
  I, J: Integer;
begin
  Raiz := TJSONObject.Create;
  try
    for I := 0 to High(TABELAS) do
    begin
      D := Definicao(TABELAS[I]);
      T := TJSONObject.Create;
      T.Add('tabela', D.Tabela);
      T.Add('titulo', D.Titulo);
      T.Add('chave', D.Chave);
      T.Add('secao', D.Secao);
      T.Add('descricao', D.Descricao);
      T.Add('textoNovo', D.TextoNovo);
      T.Add('nomeSingular', D.NomeSingular);
      T.Add('temFiltro', D.FiltroCampo <> '');
      T.Add('filtroTodos', D.FiltroTodos);

      Arr := TJSONArray.Create;
      for J := 0 to High(D.Campos) do
        Arr.Add(TJSONObject.Create([
          'nome', D.Campos[J].Nome,
          'rotulo', D.Campos[J].Rotulo,
          'tipo', TIPOS[D.Campos[J].Tipo],
          'largura', D.Campos[J].Largura,
          'obrigatorio', ocObrigatorio in D.Campos[J].Opcoes,
          'somenteLeitura', ocSomenteLeitura in D.Campos[J].Opcoes]));
      T.Add('campos', Arr);

      Arr := TJSONArray.Create;
      for J := 0 to High(D.Colunas) do
        Arr.Add(TJSONObject.Create([
          'campo', D.Colunas[J].Campo,
          'titulo', D.Colunas[J].Titulo,
          'largura', D.Colunas[J].Largura,
          'estilo', Ord(D.Colunas[J].Estilo)]));
      T.Add('colunas', Arr);

      Arr := TJSONArray.Create;
      for J := 0 to High(D.Detalhes) do
        Arr.Add(D.Detalhes[J].Rotulo);
      T.Add('detalhes', Arr);

      Raiz.Add(D.Tabela, T);
    end;
    WriteLn(Raiz.FormatJSON);
  finally
    Raiz.Free;
  end;
end.
