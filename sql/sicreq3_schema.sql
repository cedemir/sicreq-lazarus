-- =====================================================================
--  SICREQ3 - Esquema do banco (MySQL 8)
--  Derivado de sicreq2.sql. As tabelas de controle do Laravel
--  (cache, sessions) foram removidas por não serem usadas pelo
--  sistema desktop.
--
--  Para usar com os dados existentes:
--    1) mysql -u root -p < sql/sicreq3_schema.sql
--    2) mysql -u root -p sicreq3 < sql/migrar_de_sicreq2.sql
--       (copia os dados do banco sicreq2 já existente no mesmo servidor)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS sicreq3
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sicreq3;

SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------- tabelas auxiliares ----------------------
CREATE TABLE IF NOT EXISTS armazenagem (
  armazenagem_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  armazenagem_descricao VARCHAR(50) NOT NULL,
  PRIMARY KEY (armazenagem_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS editora (
  editora_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  editora_descricao VARCHAR(255) NOT NULL,
  PRIMARY KEY (editora_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS situacao_titulo (
  situacao_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  situacao_descricao VARCHAR(50) NOT NULL,
  PRIMARY KEY (situacao_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tamanho (
  tamanho_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tamanho_descricao VARCHAR(255) NOT NULL,
  tamanho_linha     DOUBLE DEFAULT NULL,
  tamanho_coluna    DOUBLE DEFAULT NULL,
  PRIMARY KEY (tamanho_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tipo_titulo (
  tipotitulo_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipotitulo_descricao VARCHAR(50) NOT NULL,
  PRIMARY KEY (tipotitulo_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS universo (
  universo_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  universo_descricao VARCHAR(50) NOT NULL,
  PRIMARY KEY (universo_codigo)
) ENGINE=InnoDB;

-- --------------------------- artistas / personagens ------------------
CREATE TABLE IF NOT EXISTS artista (
  artista_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  artista_nome      VARCHAR(50) NOT NULL,
  artista_historico VARCHAR(255) DEFAULT NULL,
  artista_foto      VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (artista_codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS personagem (
  personagem_codigo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  personagem_descricao VARCHAR(50) NOT NULL,
  universo_codigo      INT UNSIGNED NOT NULL,
  personagem_origem    TEXT,
  PRIMARY KEY (personagem_codigo),
  KEY personagem_universo_codigo_foreign (universo_codigo),
  CONSTRAINT personagem_universo_codigo_foreign FOREIGN KEY (universo_codigo)
    REFERENCES universo (universo_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS personagem_criador (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  personagem_codigo INT UNSIGNED NOT NULL,
  artista_codigo    INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY personagem_criador_personagem_codigo_artista_codigo_unique (personagem_codigo, artista_codigo),
  KEY personagem_criador_artista_codigo_foreign (artista_codigo),
  CONSTRAINT personagem_criador_artista_codigo_foreign FOREIGN KEY (artista_codigo)
    REFERENCES artista (artista_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT personagem_criador_personagem_codigo_foreign FOREIGN KEY (personagem_codigo)
    REFERENCES personagem (personagem_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS imagempersonagem (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  personagem_codigo INT UNSIGNED NOT NULL,
  imagem_codigo     INT UNSIGNED DEFAULT NULL,
  imagem_descricao  VARCHAR(150) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY imagempersonagem_personagem_codigo_foreign (personagem_codigo),
  CONSTRAINT imagempersonagem_personagem_codigo_foreign FOREIGN KEY (personagem_codigo)
    REFERENCES personagem (personagem_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------- acervo ----------------------------------
CREATE TABLE IF NOT EXISTS titulo (
  titulo_codigo        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  titulo_descricao     VARCHAR(50) NOT NULL,
  editora_codigo       INT UNSIGNED NOT NULL,
  tipotitulo_codigo    INT UNSIGNED NOT NULL,
  situacao_codigo      INT UNSIGNED NOT NULL,
  titulo_periodicidade INT DEFAULT NULL,
  titulo_origem        VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (titulo_codigo),
  KEY titulo_editora_codigo_foreign (editora_codigo),
  KEY titulo_tipotitulo_codigo_foreign (tipotitulo_codigo),
  KEY titulo_situacao_codigo_foreign (situacao_codigo),
  CONSTRAINT titulo_editora_codigo_foreign FOREIGN KEY (editora_codigo)
    REFERENCES editora (editora_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT titulo_situacao_codigo_foreign FOREIGN KEY (situacao_codigo)
    REFERENCES situacao_titulo (situacao_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT titulo_tipotitulo_codigo_foreign FOREIGN KEY (tipotitulo_codigo)
    REFERENCES tipo_titulo (tipotitulo_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exemplar (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  titulo_codigo         INT UNSIGNED NOT NULL,
  exemplar_codigo       INT UNSIGNED NOT NULL,
  exemplar_subtitulo    VARCHAR(255) DEFAULT NULL,
  exemplar_capa         VARCHAR(100) DEFAULT NULL,
  exemplar_data         TIMESTAMP NULL DEFAULT NULL,
  armazenagem_codigo    INT UNSIGNED DEFAULT NULL,
  tamanho_codigo        INT UNSIGNED DEFAULT NULL,
  exemplar_situacao     SMALLINT DEFAULT NULL,
  exemplar_numeropagina INT DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY exemplar_titulo_codigo_exemplar_codigo_unique (titulo_codigo, exemplar_codigo),
  KEY exemplar_armazenagem_codigo_foreign (armazenagem_codigo),
  KEY exemplar_tamanho_codigo_foreign (tamanho_codigo),
  CONSTRAINT exemplar_armazenagem_codigo_foreign FOREIGN KEY (armazenagem_codigo)
    REFERENCES armazenagem (armazenagem_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT exemplar_tamanho_codigo_foreign FOREIGN KEY (tamanho_codigo)
    REFERENCES tamanho (tamanho_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT exemplar_titulo_codigo_foreign FOREIGN KEY (titulo_codigo)
    REFERENCES titulo (titulo_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historia (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  titulo_codigo   INT UNSIGNED NOT NULL,
  exemplar_codigo INT UNSIGNED NOT NULL,
  historia_numero INT UNSIGNED NOT NULL,
  historia_titulo VARCHAR(50) NOT NULL,
  historia_resumo TEXT,
  historia_cor    SMALLINT NOT NULL DEFAULT 0,
  historia_original VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY historia_titulo_codigo_exemplar_codigo_historia_numero_unique (titulo_codigo, exemplar_codigo, historia_numero),
  CONSTRAINT historia_titulo_codigo_exemplar_codigo_foreign FOREIGN KEY (titulo_codigo, exemplar_codigo)
    REFERENCES exemplar (titulo_codigo, exemplar_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS artista_historia (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  titulo_codigo   INT UNSIGNED NOT NULL,
  exemplar_codigo INT UNSIGNED NOT NULL,
  historia_codigo INT UNSIGNED NOT NULL,
  artista_codigo  INT UNSIGNED NOT NULL,
  participa_artistahistoria SMALLINT DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY artista_historia_chave_unique (titulo_codigo, exemplar_codigo, historia_codigo, artista_codigo),
  KEY artista_historia_artista_codigo_foreign (artista_codigo),
  CONSTRAINT artista_historia_artista_codigo_foreign FOREIGN KEY (artista_codigo)
    REFERENCES artista (artista_codigo) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT artista_historia_historia_foreign FOREIGN KEY (titulo_codigo, exemplar_codigo, historia_codigo)
    REFERENCES historia (titulo_codigo, exemplar_codigo, historia_numero) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historiapersonagem (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  titulo_codigo     INT UNSIGNED NOT NULL,
  exemplar_codigo   INT UNSIGNED NOT NULL,
  historia_codigo   INT UNSIGNED NOT NULL,
  personagem_codigo INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY historiapersonagem_chave_unique (titulo_codigo, exemplar_codigo, historia_codigo, personagem_codigo),
  KEY historiapersonagem_personagem_codigo_foreign (personagem_codigo),
  CONSTRAINT historiapersonagem_historia_foreign FOREIGN KEY (titulo_codigo, exemplar_codigo, historia_codigo)
    REFERENCES historia (titulo_codigo, exemplar_codigo, historia_numero) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT historiapersonagem_personagem_codigo_foreign FOREIGN KEY (personagem_codigo)
    REFERENCES personagem (personagem_codigo) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------- usuários do sistema --------------------
-- O sistema também cria esta tabela sozinho na primeira execução.
-- usuario_senha guarda apenas o hash PBKDF2-HMAC-SHA1 (com sal), nunca a senha.
-- usuario_perfil: 1 = administrador, 2 = operador, 3 = consulta
CREATE TABLE IF NOT EXISTS usuario (
  usuario_codigo        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_nome          VARCHAR(80) NOT NULL,
  usuario_login         VARCHAR(40) NOT NULL,
  usuario_email         VARCHAR(120) DEFAULT NULL,
  usuario_senha         VARCHAR(200) NOT NULL,
  usuario_perfil        SMALLINT NOT NULL DEFAULT 2,
  usuario_ativo         TINYINT(1) NOT NULL DEFAULT 1,
  usuario_ultimo_acesso DATETIME DEFAULT NULL,
  usuario_criado_em     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (usuario_codigo),
  UNIQUE KEY usuario_login_unique (usuario_login)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------- valores iniciais ------------------------
INSERT IGNORE INTO armazenagem VALUES (1,'LOCAL PADRAO');
INSERT IGNORE INTO situacao_titulo VALUES (1,'ENCERRADA'),(2,'CANCELADA'),(3,'EM PUBLICAÇÃO'),(4,'INCOMPLETA');
INSERT IGNORE INTO tamanho VALUES (1,'FORMATINHO',16,21),(2,'MAGAZINE',21,28),(3,'FORMATO AMERICANO',NULL,NULL);
INSERT IGNORE INTO tipo_titulo VALUES (1,'MINI-SÉRIE'),(2,'MINI-SÉRIE ENCADERNADA'),(3,'PERIÓDICO'),(4,'ESPECIAL'),
  (5,'LIVRO DE BOLSO'),(6,'PERIODICO ENCADERNADO(TPB)'),(7,'SÉRIE ESPECIAL'),(8,'LIVRO'),(9,'ELETRONICO');
INSERT IGNORE INTO universo VALUES (1,'IMAGE'),(2,'DARK HORSE'),(3,'2000 A.D.'),(4,'WILDSTORM'),(5,'MARVEL'),
  (6,'DC'),(7,'UNIVERSO BRASIL'),(8,'UNIVERSO VARIADO'),(9,'BONELLI'),(10,'SPRIT');
