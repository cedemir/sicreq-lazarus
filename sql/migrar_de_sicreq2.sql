-- Copia todos os dados do banco sicreq2 (importado de sicreq2.sql)
-- para o banco sicreq3. Execute no mesmo servidor:
--   mysql -u root -p sicreq3 < sql/migrar_de_sicreq2.sql
USE sicreq3;
SET FOREIGN_KEY_CHECKS = 0;
REPLACE INTO armazenagem        SELECT * FROM sicreq2.armazenagem;
REPLACE INTO editora            SELECT * FROM sicreq2.editora;
REPLACE INTO situacao_titulo    SELECT * FROM sicreq2.situacao_titulo;
REPLACE INTO tamanho            SELECT * FROM sicreq2.tamanho;
REPLACE INTO tipo_titulo        SELECT * FROM sicreq2.tipo_titulo;
REPLACE INTO universo           SELECT * FROM sicreq2.universo;
REPLACE INTO artista            SELECT * FROM sicreq2.artista;
REPLACE INTO personagem         SELECT * FROM sicreq2.personagem;
REPLACE INTO personagem_criador SELECT * FROM sicreq2.personagem_criador;
REPLACE INTO imagempersonagem   SELECT * FROM sicreq2.imagempersonagem;
REPLACE INTO titulo             SELECT * FROM sicreq2.titulo;
REPLACE INTO exemplar           SELECT * FROM sicreq2.exemplar;
REPLACE INTO historia           SELECT * FROM sicreq2.historia;
REPLACE INTO artista_historia   SELECT * FROM sicreq2.artista_historia;
REPLACE INTO historiapersonagem SELECT * FROM sicreq2.historiapersonagem;
SET FOREIGN_KEY_CHECKS = 1;
