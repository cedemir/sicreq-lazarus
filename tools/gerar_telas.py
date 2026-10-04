#!/usr/bin/env python3
"""Gera as telas visuais (.pas + .lfm) de cada tabela em src/telas/.

Entrada: JSON produzido por tools/exportar_definicoes (metadados de
src/udefinicoes.pas).

    python3 tools/gerar_telas.py definicoes.json src/telas [--sobrescrever] [tabela ...]

Sem --sobrescrever, arquivos que já existem NÃO são tocados (para não
perder o que você ajustou no designer). Informe nomes de tabela para
gerar só essas.

Para cada tabela:
  ulista<tabela>.pas/.lfm   TFraLista<Tabela>   (TFrame da listagem)
  ueditar<tabela>.pas/.lfm  TFrmEditar<Tabela>  (TForm de inclusão/edição)

As telas não têm código: uCadastro/uEdicao adotam os componentes pelo nome
(veja os comentários nesses arquivos) e uTemaForm aplica o tema pelo Tag.
"""
import json, os, sys

# ---------------------------------------------------------------- tema
def col(r, g, b): return (b << 16) | (g << 8) | r
FUNDO = col(0x0B, 0x12, 0x20); CARTAO = col(0x0F, 0x17, 0x2A); ENTRADA = FUNDO
BORDA = col(0x1E, 0x29, 0x3B); TEXTO = col(0xF1, 0xF5, 0xF9); SUAVE = col(0x94, 0xA3, 0xB8)
DESTAQUE = col(0x93, 0xC5, 0xFD); PRIMARIA = col(0x25, 0x63, 0xEB); BRANCO = 0xFFFFFF

def fh(pt): return -round(pt * 96 / 72)
def q(s): return "'" + s.replace("'", "''") + "'"
def camel(t): return ''.join(p.capitalize() for p in t.split('_'))

def upper(s):
    return s.upper()

class O:
    """objeto do .lfm"""
    def __init__(s, name, cls, props=None, kids=None, raw=None):
        s.name, s.cls, s.props, s.kids, s.raw = name, cls, props or [], kids or [], raw or []
    def txt(s, ind=0):
        p = '  ' * ind
        out = [f"{p}object {s.name}: {s.cls}"]
        for k, v in s.props:
            out.append(f"{p}  {k} = {v}")
        for linha in s.raw:          # blocos prontos (ex.: Columns = < ... >)
            out.append(p + '  ' + linha)
        for c in s.kids:
            out.append(c.txt(ind + 1))
        out.append(f"{p}end")
        return "\n".join(out)

def fonte(pt, cor, bold=False):
    r = [("Font.Color", str(cor)), ("Font.Height", str(fh(pt)))]
    if bold: r.append(("Font.Style", "[fsBold]"))
    r.append(("ParentFont", "False"))
    return r

def painel(nome, align=None, h=None, cor=CARTAO, extra=None, kids=None, x=0, y=0, w=100):
    p = [("Left", str(x)), ("Height", str(h or 50)), ("Top", str(y)), ("Width", str(w))]
    if align: p.append(("Align", align))
    p += (extra or []) + [("BevelOuter", "bvNone"), ("Color", str(cor)), ("ParentColor", "False")]
    return O(nome, "TPanel", p, kids)

def label(nome, texto, x, y, pt, cor, bold=False, extra=None):
    return O(nome, "TLabel", [("Left", str(x)), ("Height", str(max(18, round(pt * 1.9)))),
                               ("Top", str(y)), ("Caption", q(texto))] + fonte(pt, cor, bold) + (extra or []))

def botao(nome, texto, tag, x, y, w, h, modal=None, extra=None):
    p = [("Tag", str(tag)), ("Left", str(x)), ("Height", str(h)), ("Top", str(y)), ("Width", str(w)),
         ("Caption", q(texto))]
    if modal: p.append(("ModalResult", str(modal)))
    return O(nome, "TButton", p + (extra or []))

def edit_centralizado(nome_edt, nome_pnl, w, cls="TEdit", extra=None):
    return O(nome_edt, cls, [("AnchorSideTop.Control", nome_pnl), ("AnchorSideTop.Side", "asrCenter"),
        ("Left", "12"), ("Height", "24"), ("Top", "9"), ("Width", str(w - 24)),
        ("Anchors", "[akTop, akLeft, akRight]"), ("BorderStyle", "bsNone"), ("Color", str(ENTRADA))]
        + fonte(10, TEXTO) + (extra or []))

def nao_visual(nome, cls, x, y, extra=None):
    # Left/Top de componentes não visuais: posição no designer
    return O(nome, cls, (extra or []) + [("Left", str(x)), ("Top", str(y))])

def largura_texto(s, pt=9):
    return int(len(s) * pt * 0.62)

# ---------------------------------------------------------------- listagem
def gerar_lista(d):
    C = camel(d['tabela'])
    acoes = d['detalhes'] + ['Editar', 'Excluir']
    larg_acoes = 24 + sum(largura_texto(a) + 22 + 8 for a in acoes)
    W = 1100
    w_novo = max(84, largura_texto('+  ' + d['textoNovo'], 10) + 50)

    trilha = painel("PnlTrilha", "alTop", 50, FUNDO, w=W, kids=[
        botao("BtnVoltar", "‹  Voltar", 2, 0, 0, 104, 34),
        label("LblTrilha", "Mestre  ›  registro", 120, 8, 10, SUAVE)])
    cab = painel("PnlCabecalho", "alTop", 112, FUNDO, y=50, w=W, kids=[
        label("LblSecao", upper(d['secao']), 0, 2, 9, DESTAQUE, True),
        label("LblTitulo", d['titulo'], 0, 24, 24, TEXTO, True),
        label("LblDescricao", d['descricao'], 0, 76, 11, SUAVE),
        botao("BtnNovo", "+  " + d['textoNovo'], 1, W - w_novo, 52, w_novo, 44, extra=[
            ("Anchors", "[akTop, akRight]"), ("AnchorSideRight.Control", "PnlCabecalho"),
            ("AnchorSideRight.Side", "asrBottom")]),
        botao("BtnImprimir", "Imprimir", 1, W - w_novo - 12 - 110, 52, 110, 44, extra=[
            ("Anchors", "[akTop, akRight]"), ("AnchorSideRight.Control", "BtnNovo"),
            ("AnchorSideRight.Side", "asrTop"), ("BorderSpacing.Right", "12")])])

    barra_kids = []
    if d['temFiltro']:
        barra_kids.append(O("CbFiltro", "TComboBox", [("Left", "780"), ("Height", "46"), ("Top", "0"),
            ("Width", "260"), ("Align", "alRight"), ("BorderSpacing.Left", "12"), ("Color", str(ENTRADA))]
            + fonte(10, TEXTO) + [("Style", "csDropDownList"), ("Text", q(d['filtroTodos']))]))
    barra_kids.append(painel("PnlBusca", "alClient", 46, ENTRADA, extra=[("Tag", "10")], w=760,
        kids=[edit_centralizado("EdtBusca", "PnlBusca", 760, extra=[
            ("TextHint", q("Pesquisar " + d['titulo'].lower() + "..."))])]))
    barra = painel("PnlBarra", "alTop", 46, CARTAO, w=1020, extra=[
        ("BorderSpacing.Left", "20"), ("BorderSpacing.Top", "20"), ("BorderSpacing.Right", "20")], kids=barra_kids)
    rodape = painel("PnlRodape", "alBottom", 40, CARTAO, y=400, w=1020, extra=[
        ("BorderSpacing.Left", "20"), ("BorderSpacing.Right", "20"), ("BorderSpacing.Bottom", "8")],
        kids=[label("LblContagem", "0 registros", 4, 12, 9, SUAVE)])

    colunas = ["Columns = <"]
    itens = [(c['campo'], upper(c['titulo']), c['largura'], c['estilo']) for c in d['colunas']]
    itens.append(("", "AÇÕES", larg_acoes, 100))
    for idx, (campo, titulo, largura, tag) in enumerate(itens):
        colunas.append("  item")
        if campo: colunas.append(f"    FieldName = {q(campo)}")
        colunas.append(f"    SizePriority = {0 if tag == 100 else 1}")
        colunas.append(f"    Tag = {tag}")
        colunas.append(f"    Title.Caption = {q(titulo)}")
        colunas.append(f"    Width = {largura}")
        colunas.append("  end>" if idx == len(itens) - 1 else "  end")
    grid = O("Grid", "TDBGrid", [("Left", "20"), ("Height", "300"), ("Top", "78"), ("Width", "1020"),
        ("Align", "alClient"), ("AutoFillColumns", "True"), ("BorderSpacing.Left", "20"),
        ("BorderSpacing.Top", "12"), ("BorderSpacing.Right", "20"), ("BorderStyle", "bsNone"),
        ("Color", str(CARTAO)), ("DataSource", "DsLista"), ("DefaultRowHeight", "46"),
        ("FixedColor", str(CARTAO)), ("Flat", "True")] + fonte(10, TEXTO) + [
        ("Options", "[dgTitles, dgRowLines, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit, dgDisableDelete, dgDisableInsert]"),
        ("ReadOnly", "True"), ("TitleFont.Color", str(SUAVE)), ("TitleFont.Height", str(fh(8))),
        ("TitleFont.Style", "[fsBold]")], raw=colunas)
    cartao = painel("PnlCartao", "alClient", 470, CARTAO, y=162, w=W, extra=[("Tag", "11"), ("BorderSpacing.Top", "22")],
                    kids=[barra, rodape, grid])

    raiz = O(f"FraLista{C}", f"TFraLista{C}", [("Left", "0"), ("Height", "640"), ("Top", "0"), ("Width", str(W)),
        ("ClientHeight", "640"), ("ClientWidth", str(W)), ("Color", str(FUNDO)), ("ParentColor", "False"),
        ("TabOrder", "0")],
        [trilha, cab, cartao,
         nao_visual("QryLista", "TZReadOnlyQuery", 940, 4),
         nao_visual("DsLista", "TDataSource", 1020, 4, [("DataSet", "QryLista")])])
    lfm = raiz.txt() + "\n"

    campos = ["BtnImprimir: TButton", "BtnNovo: TButton", "BtnVoltar: TButton"]
    if d['temFiltro']: campos.append("CbFiltro: TComboBox")
    campos += ["DsLista: TDataSource", "EdtBusca: TEdit", "Grid: TDBGrid", "LblContagem: TLabel",
               "LblDescricao: TLabel", "LblSecao: TLabel", "LblTitulo: TLabel", "LblTrilha: TLabel",
               "PnlBarra: TPanel", "PnlBusca: TPanel", "PnlCabecalho: TPanel", "PnlCartao: TPanel",
               "PnlRodape: TPanel", "PnlTrilha: TPanel", "QryLista: TZReadOnlyQuery"]
    unidade = f"ulista{d['tabela'].replace('_', '')}"
    pas = f"""unit {unidade};

{{ Listagem de "{d['titulo']}" (tabela {d['tabela']}).
  Tela visual: edite {unidade}.lfm no designer.

  Não há código aqui: uCadastro.TPaginaCadastro adota os componentes pelo
  nome (Grid, QryLista, EdtBusca, CbFiltro, BtnNovo, BtnImprimir, BtnVoltar,
  LblTrilha, LblContagem, PnlTrilha). Não renomeie esses componentes.
  Colunas do Grid: Tag = estilo (0 normal, 1 negrito, 2 número âmbar,
  3 suave); a coluna com Tag = 100 é a de AÇÕES (botões por linha).
  O tema escuro é aplicado pelo Tag (veja uTemaForm). }}

{{$mode objfpc}}{{$H+}}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, DBGrids, DB, ZDataset;

type

  {{ TFraLista{C} }}

  TFraLista{C} = class(TFrame)
{chr(10).join('    ' + c + ';' for c in campos)}
  end;

implementation

uses
  uTelas;

{{$R *.lfm}}

initialization
  RegistrarLista({q(d['tabela'])}, TFraLista{C});

end.
"""
    return unidade, pas, lfm, f"FraLista{C}", "Frame"

# ---------------------------------------------------------------- edição
def gerar_edicao(d):
    C = camel(d['tabela'])
    LF, M, ALT_ROT = 900, 28, 22
    util = LF - 2 * M
    kids, campos_cls = [], []
    x, y, alt_linha = M, 20, 0
    for c in d['campos']:
        nome = c['nome']
        w = min(c['largura'], util)
        if c['tipo'] == 'imagem': w = min(c['largura'] + 150, util)
        if c['tipo'] == 'memo': w = util
        h = 96 if c['tipo'] == 'memo' else 42
        if x > M and x + w > M + util:
            x = M; y += alt_linha + 16; alt_linha = 0
        rot = c['rotulo'] + (' *' if c['obrigatorio'] else '')
        kids.append(label(f"Lbl_{nome}", rot, x, y, 9, SUAVE, True))
        campos_cls.append(f"Lbl_{nome}: TLabel")
        ro = [("ReadOnly", "True")] if c['somenteLeitura'] else []
        base_db = [("DataField", q(nome)), ("DataSource", "DsRegistro")]
        if c['tipo'] == 'lookup':
            kids.append(O(f"Edt_{nome}", "TDBLookupComboBox", [("Left", str(x)), ("Height", "36"),
                ("Top", str(y + ALT_ROT)), ("Width", str(w)), ("Color", str(ENTRADA))] + base_db
                + fonte(10, TEXTO) + ro + [("Style", "csDropDownList")]))
            campos_cls.append(f"Edt_{nome}: TDBLookupComboBox")
        elif c['tipo'] == 'data':
            kids.append(O(f"Edt_{nome}", "TDBDateEdit", [("Left", str(x)), ("Height", "36"),
                ("Top", str(y + ALT_ROT)), ("Width", str(w)), ("Color", str(ENTRADA))] + base_db
                + fonte(10, TEXTO) + ro))
            campos_cls.append(f"Edt_{nome}: TDBDateEdit")
        else:
            wc = w - 150 if c['tipo'] == 'imagem' else w
            if c['tipo'] == 'memo':
                edt = O(f"Edt_{nome}", "TDBMemo", [("Left", "8"), ("Height", "80"), ("Top", "8"), ("Width", str(wc - 16)),
                    ("Align", "alClient"), ("BorderSpacing.Around", "8"), ("BorderStyle", "bsNone"),
                    ("Color", str(ENTRADA))] + base_db + fonte(10, TEXTO) + ro + [("ScrollBars", "ssAutoVertical")])
                campos_cls.append(f"Edt_{nome}: TDBMemo")
            else:
                edt = edit_centralizado(f"Edt_{nome}", f"Pnl_{nome}", wc, "TDBEdit", base_db + ro)
                campos_cls.append(f"Edt_{nome}: TDBEdit")
            kids.append(painel(f"Pnl_{nome}", None, h, ENTRADA, x=x, y=y + ALT_ROT, w=wc,
                               extra=[("Tag", "10")], kids=[edt]))
            campos_cls.append(f"Pnl_{nome}: TPanel")
            if c['tipo'] == 'imagem':
                kids.append(botao(f"BtnArq_{nome}", "Escolher...", 2, x + w - 142, y + ALT_ROT, 84, h))
                kids.append(botao(f"BtnVer_{nome}", "Ver", 2, x + w - 52, y + ALT_ROT, 52, h))
                campos_cls += [f"BtnArq_{nome}: TButton", f"BtnVer_{nome}: TButton"]
        alt_linha = max(alt_linha, ALT_ROT + h)
        x += w + 20
    alt_campos = y + alt_linha + 28
    altura = 108 + 1 + alt_campos + 76

    topo = painel("PnlTopo", "alTop", 108, CARTAO, w=LF, kids=[
        label("LblSecao", upper(d['titulo']), M, 18, 8, DESTAQUE, True),
        label("LblTitulo", "Editar " + d['nomeSingular'], M, 36, 17, TEXTO, True),
        label("LblTrilha", "", M, 76, 9, SUAVE)])
    divisa = painel("PnlDivisa", "alTop", 1, BORDA, y=108, w=LF)
    rodape = painel("PnlRodape", "alBottom", 76, CARTAO, y=altura - 76, w=LF, kids=[
        painel("PnlLinha", "alTop", 1, BORDA, w=LF),
        label("LblDica", "* campos obrigatórios    F2 salva    Esc cancela", M, 32, 8, SUAVE),
        botao("BtnCancelar", "Cancelar", 2, LF - M - 130 - 12 - 120, 20, 120, 40, modal=2),
        botao("BtnSalvar", "Salvar", 1, LF - M - 130, 20, 130, 40)])
    area = painel("PnlCampos", "alClient", alt_campos, CARTAO, y=109, w=LF, kids=kids)
    raiz = O(f"FrmEditar{C}", f"TFrmEditar{C}", [("Left", "400"), ("Height", str(altura)), ("Top", "150"),
        ("Width", str(LF)), ("BorderStyle", "bsDialog"), ("Caption", q(d['titulo'])),
        ("ClientHeight", str(altura)), ("ClientWidth", str(LF)), ("Color", str(CARTAO)),
        ("KeyPreview", "True"), ("Position", "poMainFormCenter"), ("LCLVersion", "'4.8.0.0'")],
        [topo, divisa, rodape, area,
         nao_visual("QryRegistro", "TZQuery", 760, 10),
         nao_visual("DsRegistro", "TDataSource", 830, 10, [("DataSet", "QryRegistro")])])
    lfm = raiz.txt() + "\n"

    campos = sorted(set(campos_cls) | {
        "BtnCancelar: TButton", "BtnSalvar: TButton", "DsRegistro: TDataSource", "LblDica: TLabel",
        "LblSecao: TLabel", "LblTitulo: TLabel", "LblTrilha: TLabel", "PnlCampos: TPanel",
        "PnlDivisa: TPanel", "PnlLinha: TPanel", "PnlRodape: TPanel", "PnlTopo: TPanel",
        "QryRegistro: TZQuery"}, key=str.lower)
    unidade = f"ueditar{d['tabela'].replace('_', '')}"
    pas = f"""unit {unidade};

{{ Inclusão/edição de "{d['titulo']}" (tabela {d['tabela']}).
  Tela visual: edite {unidade}.lfm no designer.

  Não há código aqui: uEdicao adota os componentes pelo nome. Cada campo
  da tabela tem Lbl_<campo> e Edt_<campo> (TDBEdit, TDBMemo, TDBDateEdit
  ou TDBLookupComboBox ligado a DsRegistro/DataField); caixas de texto
  ficam dentro de Pnl_<campo> (Tag 10). Campos de imagem têm
  BtnArq_<campo> e BtnVer_<campo>. Não renomeie esses componentes nem
  QryRegistro, DsRegistro, BtnSalvar, BtnCancelar, LblTitulo, LblTrilha.
  Os TDBLookupComboBox viram a combo escura ao abrir (itens vêm de
  uDefinicoes). Obrigatórios, numeração automática e valores padrão também
  ficam em uDefinicoes. }}

{{$mode objfpc}}{{$H+}}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, DBCtrls, DBExtCtrls,
  DB, ZDataset;

type

  {{ TFrmEditar{C} }}

  TFrmEditar{C} = class(TForm)
{chr(10).join('    ' + c + ';' for c in campos)}
  end;

implementation

uses
  uTelas;

{{$R *.lfm}}

initialization
  RegistrarEdicao({q(d['tabela'])}, TFrmEditar{C});

end.
"""
    return unidade, pas, lfm, f"FrmEditar{C}", "Form"

# ---------------------------------------------------------------- principal
def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    sobrescrever = '--sobrescrever' in sys.argv
    if len(args) < 2:
        print(__doc__); sys.exit(1)
    defs = json.load(open(args[0], encoding='utf-8'))
    destino = args[1]
    so = set(args[2:])
    os.makedirs(destino, exist_ok=True)
    gerados = []
    for tabela, d in defs.items():
        if so and tabela not in so:
            continue
        telas = [gerar_lista(d)]
        if tabela != 'usuario':          # usuário tem formulário próprio (uusuarios)
            telas.append(gerar_edicao(d))
        for unidade, pas, lfm, comp, base in telas:
            arq = os.path.join(destino, unidade)
            if not sobrescrever and (os.path.exists(arq + '.pas') or os.path.exists(arq + '.lfm')):
                print('mantido (já existe):', unidade)
                continue
            open(arq + '.pas', 'w', encoding='utf-8').write(pas)
            open(arq + '.lfm', 'w', encoding='utf-8').write(lfm)
            gerados.append((unidade, comp, base))
            print('gerado:', unidade)
    print(f'{len(gerados)} tela(s) gerada(s).')

if __name__ == '__main__':
    main()
