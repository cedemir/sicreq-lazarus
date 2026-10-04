unit uPrincipal;

{ Janela principal no padrão "painel web":

    +-----------+--------------------------------------------------+
    | [SQ]SICREQ| ● Conectado ao MySQL ...                  [Sair] |
    | BANCO     +--------------------------------------------------+
    | [sicreq3] |                                                  |
    | Painel    |   página atual (TPaginaCadastro / TPaginaPainel) |
    | Títulos   |                                                  |
    | ...       |                                                  |
    | (usuário) |                                                  |
    +-----------+--------------------------------------------------+

  As páginas ficam numa pilha: o botão de detalhe de uma linha empilha a
  página filha; "Voltar" desempilha. Escolher um item do menu limpa a pilha. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLType, LazUTF8, uTema, uEscolha, uDefinicoes, uCadastro, uPaginas, uSessao;

type

  { TFrmPrincipal }

  TFrmPrincipal = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    Lateral, Direita, Cabecalho, Conteudo: TPanel;
    LblConexao, LblBanco, LblUsuario, LblHost: TLabel;
    BadgeUsuario, BadgeVersao, Avatar: TCartao;
    FMenu: array of TBotao;
    FChavesMenu: array of string;
    FPilha: TFPList;

    procedure MontarLateral;
    procedure MontarCabecalho;
    procedure AdicionarItemMenu(AParent: TWinControl; var Y: Integer;
      const AIcone, ATexto, AChave: string);
    procedure AdicionarGrupoMenu(AParent: TWinControl; var Y: Integer;
      const ATexto: string);
    procedure AjustarBadge(ABadge: TCartao; const ATexto: string);
    procedure AtualizarConexao;
    procedure AtualizarUsuario;
    procedure MarcarMenu(const AChave: string);

    function PaginaAtual: TControl;
    procedure LimparPilha;
    procedure Empilhar(APagina: TControl);
    procedure AbrirPagina(const AChave: string);

    procedure MenuClick(Sender: TObject);
    procedure SairClick(Sender: TObject);
    procedure AbrirTabela(const ATabela: string);
    procedure AbrirDetalhe(const ATabela: string; const AFixos: TFiltrosFixos;
      const ATrilha: string);
    procedure Voltar(Sender: TObject);
    procedure ConexaoAlterada(Sender: TObject);
  public
    destructor Destroy; override;
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

uses
  uDM, uLogin;

{$R *.lfm}

const
  LARGURA_LATERAL = 256;

{ TFrmPrincipal }

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  FPilha := TFPList.Create;
  Color := corFundo;
  Font.Size := 10;

  MontarLateral;

  { à direita da lateral: cabeçalho + conteúdo }
  Direita := NovoPainel(Self, Self, alClient, corFundo, 0);
  Cabecalho := NovoPainel(Self, Direita, alTop, corFundo, 72);
  Conteudo := NovoPainel(Self, Direita, alClient, corFundo, 0);
  MontarCabecalho;

  AtualizarConexao;
  AbrirPagina('painel');
end;

destructor TFrmPrincipal.Destroy;
begin
  FPilha.Free;
  inherited Destroy;
end;

{ ------------------------------ lateral ------------------------------ }

procedure TFrmPrincipal.MontarLateral;
var
  Topo, Rodape, Divisa: TPanel;
  Logo, CartaoBanco, CaixaBanco: TCartao;
  Rolagem: TScrollBox;
  Y: Integer;
begin
  Lateral := NovoPainel(Self, Self, alLeft, corLateral, LARGURA_LATERAL);
  Divisa := NovoPainel(Self, Lateral, alRight, corBorda, 1);
  Divisa.Width := 1;

  { logotipo + cartão do banco }
  Topo := NovoPainel(Self, Lateral, alTop, corLateral, 230);
  Logo := NovoCartao(Self, Topo, corLateral);
  Logo.Cor := corPrimaria;
  Logo.CorBorda := clNone;
  Logo.Raio := 10;
  Logo.Texto := 'SQ';
  Logo.Font.Style := [fsBold];
  Logo.Font.Size := 12;
  Logo.SetBounds(26, 26, 42, 42);
  NovoRotulo(Self, Topo, 'SICREQ', 14, clWhite, True).SetBounds(80, 34, 160, 26);

  CartaoBanco := NovoCartao(Self, Topo, corLateral);
  CartaoBanco.Cor := corLateral;
  CartaoBanco.SetBounds(20, 96, LARGURA_LATERAL - 42, 122);
  NovoRotulo(Self, CartaoBanco, 'BANCO DE DADOS', 8, corTextoSuave, True).SetBounds(14, 14, 180, 16);
  CaixaBanco := NovaCaixa(Self, CartaoBanco, corLateral);
  CaixaBanco.SetBounds(12, 36, CartaoBanco.Width - 24, 42);
  LblBanco := NovoRotulo(Self, CaixaBanco, '', 11, clWhite);
  LblBanco.SetBounds(14, 10, CaixaBanco.Width - 28, 22);

  BadgeUsuario := NovoCartao(Self, CartaoBanco, corLateral);
  BadgeUsuario.Cor := corBadgeAzul;
  BadgeUsuario.CorBorda := clNone;
  BadgeUsuario.Raio := 10;
  BadgeUsuario.Font.Size := 8;
  BadgeUsuario.Font.Style := [fsBold];
  BadgeUsuario.CorTexto := corDestaque;
  BadgeUsuario.SetBounds(12, 88, 90, 22);

  BadgeVersao := NovoCartao(Self, CartaoBanco, corLateral);
  BadgeVersao.Cor := corSucessoFundo;
  BadgeVersao.CorBorda := clNone;
  BadgeVersao.Raio := 10;
  BadgeVersao.Font.Size := 8;
  BadgeVersao.Font.Style := [fsBold];
  BadgeVersao.CorTexto := corSucesso;
  BadgeVersao.SetBounds(108, 88, 90, 22);

  { rodapé: usuário }
  Rodape := NovoPainel(Self, Lateral, alBottom, corLateral, 86);
  NovoPainel(Self, Rodape, alTop, corBorda, 1).BorderSpacing.Left := 18;
  Avatar := NovoCartao(Self, Rodape, corLateral);
  Avatar.Cor := corPrimaria;
  Avatar.CorBorda := clNone;
  Avatar.Raio := 20;
  Avatar.Font.Size := 12;
  Avatar.Font.Style := [fsBold];
  Avatar.SetBounds(24, 24, 40, 40);
  LblUsuario := NovoRotulo(Self, Rodape, '', 11, clWhite, True);
  LblUsuario.SetBounds(76, 24, 170, 20);
  LblHost := NovoRotulo(Self, Rodape, '', 9, corTextoSuave);
  LblHost.SetBounds(76, 46, 170, 18);

  { itens de menu (rolam se a janela for baixa) }
  Rolagem := TScrollBox.Create(Self);
  Rolagem.Parent := Lateral;
  Rolagem.Align := alClient;
  Rolagem.BorderStyle := bsNone;
  Rolagem.Color := corLateral;
  Rolagem.HorzScrollBar.Visible := False;

  Y := 4;
  AdicionarItemMenu(Rolagem, Y, '▦', 'Painel', 'painel');
  AdicionarItemMenu(Rolagem, Y, '▣', 'Títulos', 'titulo');
  AdicionarItemMenu(Rolagem, Y, '✎', 'Artistas', 'artista');
  AdicionarItemMenu(Rolagem, Y, '◉', 'Personagens', 'personagem');
  AdicionarGrupoMenu(Rolagem, Y, 'TABELAS');
  AdicionarItemMenu(Rolagem, Y, '▤', 'Editoras', 'editora');
  AdicionarItemMenu(Rolagem, Y, '◎', 'Universos', 'universo');
  AdicionarItemMenu(Rolagem, Y, '▧', 'Tipos de título', 'tipo_titulo');
  AdicionarItemMenu(Rolagem, Y, '◆', 'Situações', 'situacao_titulo');
  AdicionarItemMenu(Rolagem, Y, '▭', 'Tamanhos', 'tamanho');
  AdicionarItemMenu(Rolagem, Y, '▥', 'Armazenagem', 'armazenagem');
  AdicionarGrupoMenu(Rolagem, Y, 'SISTEMA');
  AdicionarItemMenu(Rolagem, Y, '≡', 'Relatórios', 'relatorios');
  AdicionarItemMenu(Rolagem, Y, '⚙', 'Configurações', 'config');
  { por último, para que ao ficar oculto (não administrador) não deixe buraco }
  AdicionarItemMenu(Rolagem, Y, '♟', 'Usuários', 'usuario');
end;

procedure TFrmPrincipal.AdicionarItemMenu(AParent: TWinControl; var Y: Integer;
  const AIcone, ATexto, AChave: string);
var
  B: TBotao;
  N: Integer;
begin
  B := NovoBotao(Self, AParent, ATexto, ebMenu, @MenuClick, corLateral);
  B.Icone := AIcone;
  B.Font.Size := 11;
  B.SetBounds(18, Y, LARGURA_LATERAL - 38, 44);
  N := Length(FMenu);
  SetLength(FMenu, N + 1);
  SetLength(FChavesMenu, N + 1);
  FMenu[N] := B;
  FChavesMenu[N] := AChave;
  B.Tag := N;
  Inc(Y, 48);
end;

procedure TFrmPrincipal.AdicionarGrupoMenu(AParent: TWinControl; var Y: Integer;
  const ATexto: string);
begin
  Inc(Y, 10);
  NovoRotulo(Self, AParent, ATexto, 8, corTextoSuave, True).SetBounds(32, Y, 180, 16);
  Inc(Y, 24);
end;

procedure TFrmPrincipal.AjustarBadge(ABadge: TCartao; const ATexto: string);
begin
  ABadge.Texto := ATexto;
  ABadge.Width := LarguraTexto(ATexto, 8, True) + 20;
  ABadge.Invalidate;
end;

{ ------------------------------ cabeçalho ------------------------------ }

procedure TFrmPrincipal.MontarCabecalho;
var
  Ponto: TCartao;
  BtnSair: TBotao;
begin
  NovoPainel(Self, Cabecalho, alBottom, corBorda, 1);

  Ponto := NovoCartao(Self, Cabecalho, corFundo);
  Ponto.Cor := corSucesso;
  Ponto.CorBorda := clNone;
  Ponto.Raio := 5;
  Ponto.SetBounds(32, 31, 10, 10);

  LblConexao := NovoRotulo(Self, Cabecalho, '', 9, corTextoMenu);
  LblConexao.SetBounds(50, 27, 800, 18);

  BtnSair := NovoBotao(Self, Cabecalho, 'Sair', ebSecundario, @SairClick, corFundo);
  BtnSair.Height := 42;
  BtnSair.Top := 15;
  BtnSair.AnchorSide[akRight].Control := Cabecalho;
  BtnSair.AnchorSide[akRight].Side := asrRight;
  BtnSair.BorderSpacing.Right := 30;
  BtnSair.Anchors := [akTop, akRight];
end;

procedure TFrmPrincipal.AtualizarConexao;
var
  C: TConfigBanco;
  Versao: string;
begin
  C := DM.Config;
  if DM.Conexao.Connected then
  begin
    Versao := DM.Conexao.ServerVersionStr;
    LblConexao.Caption := Format('Conectado ao MySQL  ·  %s@%s:%d', [C.Banco, C.Host, C.Porta]);
  end
  else
  begin
    Versao := '';
    LblConexao.Caption := 'Desconectado';
  end;
  LblBanco.Caption := C.Banco;
  AjustarBadge(BadgeUsuario, NomePerfil(Sessao.Perfil));
  if Versao <> '' then
    AjustarBadge(BadgeVersao, 'MySQL ' + Copy(Versao, 1, 6))
  else
    AjustarBadge(BadgeVersao, 'offline');
  BadgeVersao.Left := BadgeUsuario.Left + BadgeUsuario.Width + 8;
  AtualizarUsuario;
end;

{ dados do usuário logado: rodapé da lateral, selo do perfil, menu Usuários }
procedure TFrmPrincipal.AtualizarUsuario;
var
  I: Integer;
begin
  LblUsuario.Caption := Sessao.Nome;
  LblHost.Caption := Sessao.Login + '  ·  ' + NomePerfil(Sessao.Perfil);
  Avatar.Texto := UTF8UpperCase(UTF8Copy(Sessao.Nome, 1, 1));
  Avatar.Invalidate;
  AjustarBadge(BadgeUsuario, NomePerfil(Sessao.Perfil));
  BadgeVersao.Left := BadgeUsuario.Left + BadgeUsuario.Width + 8;
  for I := 0 to High(FMenu) do
    if FChavesMenu[I] = 'usuario' then
      FMenu[I].Visible := EhAdministrador;
end;

procedure TFrmPrincipal.MarcarMenu(const AChave: string);
var
  I: Integer;
begin
  for I := 0 to High(FMenu) do
    FMenu[I].Ativo := FChavesMenu[I] = AChave;
end;

{ ------------------------------ páginas ------------------------------ }

function TFrmPrincipal.PaginaAtual: TControl;
begin
  if FPilha.Count = 0 then
    Result := nil
  else
    Result := TControl(FPilha[FPilha.Count - 1]);
end;

procedure TFrmPrincipal.LimparPilha;
var
  I: Integer;
begin
  { ReleaseComponent: a página pode estar no meio de um evento próprio }
  for I := FPilha.Count - 1 downto 0 do
  begin
    TControl(FPilha[I]).Visible := False;
    Application.ReleaseComponent(TComponent(FPilha[I]));
  end;
  FPilha.Clear;
end;

procedure TFrmPrincipal.Empilhar(APagina: TControl);
begin
  if PaginaAtual <> nil then
    PaginaAtual.Visible := False;
  FPilha.Add(APagina);
  APagina.Visible := True;
  if APagina is TPaginaCadastro then
    TPaginaCadastro(APagina).FocarBusca;
end;

procedure TFrmPrincipal.AbrirPagina(const AChave: string);
var
  P: TPaginaCadastro;
begin
  Screen.Cursor := crHourGlass;
  try
    LimparPilha;
    MarcarMenu(AChave);
    if AChave = 'painel' then
      Empilhar(TPaginaPainel.Criar(Self, Conteudo, @AbrirTabela))
    else if AChave = 'relatorios' then
      Empilhar(TPaginaRelatorios.Criar(Self, Conteudo))
    else if AChave = 'config' then
      Empilhar(TPaginaConfiguracoes.Criar(Self, Conteudo, @ConexaoAlterada))
    else
    begin
      P := TPaginaCadastro.Criar(Self, Conteudo, Definicao(AChave), nil, '');
      P.OnDetalhe := @AbrirDetalhe;
      Empilhar(P);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFrmPrincipal.AbrirTabela(const ATabela: string);
begin
  AbrirPagina(ATabela);
end;

procedure TFrmPrincipal.AbrirDetalhe(const ATabela: string;
  const AFixos: TFiltrosFixos; const ATrilha: string);
var
  P: TPaginaCadastro;
begin
  P := TPaginaCadastro.Criar(Self, Conteudo, Definicao(ATabela), AFixos, ATrilha);
  P.OnDetalhe := @AbrirDetalhe;
  P.OnVoltar := @Voltar;
  Empilhar(P);
end;

procedure TFrmPrincipal.Voltar(Sender: TObject);
var
  Topo: TControl;
begin
  if FPilha.Count < 2 then
    Exit;
  Topo := PaginaAtual;
  FPilha.Delete(FPilha.Count - 1);
  Topo.Visible := False;
  Application.ReleaseComponent(Topo);
  PaginaAtual.Visible := True;
  if PaginaAtual is TPaginaCadastro then
    TPaginaCadastro(PaginaAtual).Recarregar;   // contadores podem ter mudado
end;

procedure TFrmPrincipal.ConexaoAlterada(Sender: TObject);
begin
  AtualizarConexao;
  AbrirPagina('config');
end;

{ ------------------------------ eventos ------------------------------ }

procedure TFrmPrincipal.MenuClick(Sender: TObject);
begin
  AbrirPagina(FChavesMenu[TComponent(Sender).Tag]);
end;

{ Sair = encerrar a sessão e voltar ao login (Esc no login fecha o sistema) }
procedure TFrmPrincipal.SairClick(Sender: TObject);
begin
  if not Confirmar('Sair', 'Encerrar a sessão de ' + Sessao.Nome + '?', 'Sair') then
    Exit;
  LimparPilha;
  Hide;
  if ExecutarLogin then
  begin
    AtualizarConexao;
    Show;
    AbrirPagina('painel');
  end
  else
    Application.Terminate;
end;

procedure TFrmPrincipal.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  P: TPaginaCadastro;
begin
  if EscolhaAberta or not (PaginaAtual is TPaginaCadastro) then
    Exit;
  P := TPaginaCadastro(PaginaAtual);
  if (ssCtrl in Shift) and (Key = VK_N) then
  begin
    Key := 0;
    P.Novo;
  end
  else if (ssCtrl in Shift) and (Key = VK_F) then
  begin
    Key := 0;
    P.FocarBusca;
  end
  else if Key = VK_F5 then
  begin
    Key := 0;
    P.Recarregar;
  end
  else if (Key = VK_BACK) and (ssAlt in Shift) then
  begin
    Key := 0;
    Voltar(nil);
  end;
end;

end.
