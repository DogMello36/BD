/* =====================================================
   CRIAÇÃO DAS TABELAS
   ===================================================== */

CREATE TABLE dbo.CLIENTES (
    COD_CLIENTE NUMERIC(18,0) IDENTITY(1,1) PRIMARY KEY,
    RG VARCHAR(9) NOT NULL,
    NOME VARCHAR(50) NOT NULL,
    ENDERECO VARCHAR(50),
    BAIRRO VARCHAR(30),
    CIDADE VARCHAR(30),
    ESTADO CHAR(2) NOT NULL,
    TELEFONE VARCHAR(15),
    EMAIL VARCHAR(30),
    DATANASCIMENTO DATETIME,
    SEXO CHAR(1)
);

CREATE TABLE dbo.CATEGORIA (
    COD_CATEGORIA NUMERIC(10,0) IDENTITY(1,1) PRIMARY KEY,
    NOME_CATEGORIA VARCHAR(20) NOT NULL
);

CREATE TABLE dbo.FILME (
    COD_FILME NUMERIC(18,0) IDENTITY(1,1) PRIMARY KEY,
    FILME VARCHAR(30) NOT NULL,
    COD_CATEGORIA NUMERIC(10,0) NOT NULL,
    DIRETOR VARCHAR(50) NOT NULL,
    VALOR_LOCACAO FLOAT NOT NULL,
    STATUS VARCHAR(10) NOT NULL DEFAULT 'disponivel'
);

CREATE TABLE dbo.LOCACOES (
    COD_LOCACAO NUMERIC(18,0) IDENTITY(1,1),
    COD_CLIENTE NUMERIC(18,0) NOT NULL,
    COD_FILME NUMERIC(18,0) NOT NULL,
    DATA_LOCACAO DATETIME NOT NULL,
    DATA_EXPIRACAO DATETIME NULL,
    DATA_DEVOLUCAO DATETIME NULL,
    CONSTRAINT PK_LOCACAO PRIMARY KEY (COD_LOCACAO)
);

/* =====================================================
   FOREIGN KEYS
   ===================================================== */

ALTER TABLE dbo.LOCACOES
ADD CONSTRAINT FK_LOCACOES_CLIENTE
FOREIGN KEY (COD_CLIENTE) REFERENCES dbo.CLIENTES(COD_CLIENTE);

ALTER TABLE dbo.LOCACOES
ADD CONSTRAINT FK_LOCACOES_FILME
FOREIGN KEY (COD_FILME) REFERENCES dbo.FILME(COD_FILME);

ALTER TABLE dbo.FILME
ADD CONSTRAINT FK_FILME_CATEGORIA
FOREIGN KEY (COD_CATEGORIA) REFERENCES dbo.CATEGORIA(COD_CATEGORIA);

/* =====================================================
   CRUD CLIENTE
   ===================================================== */

   go
CREATE OR ALTER PROCEDURE Inclui_Cliente
    @RG VARCHAR(9),
    @NOME VARCHAR(50),
    @ENDERECO VARCHAR(50),
    @BAIRRO VARCHAR(30),
    @CIDADE VARCHAR(30),
    @ESTADO CHAR(2),
    @TELEFONE VARCHAR(15),
    @EMAIL VARCHAR(30),
    @DATANASCIMENTO DATETIME,
    @SEXO CHAR(1)
AS
BEGIN
    INSERT INTO CLIENTES VALUES
    (
        @RG, @NOME, @ENDERECO, @BAIRRO,
        @CIDADE, @ESTADO, @TELEFONE,
        @EMAIL, @DATANASCIMENTO, @SEXO
    );
END;
GO

CREATE OR ALTER PROCEDURE Mostra_Clientes
AS
BEGIN
    SELECT * FROM CLIENTES;
END;
GO

CREATE OR ALTER PROCEDURE Mostra_Cliente_Por_ID
    @ID NUMERIC(18,0)
AS
BEGIN
    SELECT * FROM CLIENTES
    WHERE COD_CLIENTE = @ID;
END;
GO

CREATE OR ALTER PROCEDURE Alterar_Cliente
    @COD_CLIENTE NUMERIC(18,0),
    @RG VARCHAR(9),
    @NOME VARCHAR(50),
    @ENDERECO VARCHAR(50),
    @BAIRRO VARCHAR(30),
    @CIDADE VARCHAR(30),
    @ESTADO CHAR(2),
    @TELEFONE VARCHAR(15),
    @EMAIL VARCHAR(30),
    @DATANASCIMENTO DATETIME,
    @SEXO CHAR(1)
AS
BEGIN
    UPDATE CLIENTES
    SET
        RG = @RG,
        NOME = @NOME,
        ENDERECO = @ENDERECO,
        BAIRRO = @BAIRRO,
        CIDADE = @CIDADE,
        ESTADO = @ESTADO,
        TELEFONE = @TELEFONE,
        EMAIL = @EMAIL,
        DATANASCIMENTO = @DATANASCIMENTO,
        SEXO = @SEXO
    WHERE COD_CLIENTE = @COD_CLIENTE;
END;
GO

CREATE OR ALTER PROCEDURE Deleta_Cliente
    @ID NUMERIC(18,0)
AS
BEGIN
    DELETE FROM LOCACOES WHERE COD_CLIENTE = @ID;
    DELETE FROM CLIENTES WHERE COD_CLIENTE = @ID;
END;
GO

/* =====================================================
   CONSULTAS
   ===================================================== */

CREATE OR ALTER PROCEDURE MostraClientesAniversarioPorMes
    @MES NUMERIC(2,0)
AS
BEGIN
    SELECT NOME, DAY(DATANASCIMENTO) AS DIA
    FROM CLIENTES
    WHERE MONTH(DATANASCIMENTO) = @MES;
END;
GO

CREATE OR ALTER PROCEDURE TodosPorMes
AS
BEGIN
    SELECT M.MES, COUNT(C.COD_CLIENTE) AS TOTAL
    FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) M(MES)
    LEFT JOIN CLIENTES C
        ON MONTH(C.DATANASCIMENTO) = M.MES
    GROUP BY M.MES;
END;
GO

CREATE OR ALTER PROCEDURE SelecionarClienteCidadeIdade
    @CIDADE VARCHAR(30),
    @IDADE INT
AS
BEGIN
    SELECT
        NOME,
        DATANASCIMENTO,
        (DATEDIFF(YEAR, DATANASCIMENTO, GETDATE())
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, DATANASCIMENTO, GETDATE()), DATANASCIMENTO) > GETDATE()
            THEN 1 ELSE 0 END) AS IDADE
    FROM CLIENTES
    WHERE CIDADE = @CIDADE
    AND (DATEDIFF(YEAR, DATANASCIMENTO, GETDATE())
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, DATANASCIMENTO, GETDATE()), DATANASCIMENTO) > GETDATE()
            THEN 1 ELSE 0 END) <= @IDADE;
END;
GO

/* =====================================================
   LOCAÇÃO
   ===================================================== */

CREATE OR ALTER PROCEDURE InserirLocacao
    @ID_CLIENTE NUMERIC(18,0),
    @ID_FILME NUMERIC(18,0)
AS
BEGIN
    INSERT INTO LOCACOES
    VALUES (@ID_CLIENTE, @ID_FILME, GETDATE(), DATEADD(DAY,5,GETDATE()), NULL);

    UPDATE FILME
    SET STATUS = 'alugado'
    WHERE COD_FILME = @ID_FILME;
END;
GO

CREATE OR ALTER PROCEDURE Devolver_Filme
    @ID_LOCACAO NUMERIC(18,0)
AS
BEGIN
    UPDATE LOCACOES
    SET DATA_DEVOLUCAO = GETDATE()
    WHERE COD_LOCACAO = @ID_LOCACAO;

    UPDATE FILME
    SET STATUS = 'disponivel'
    WHERE COD_FILME = (
        SELECT COD_FILME
        FROM LOCACOES
        WHERE COD_LOCACAO = @ID_LOCACAO
    );
END;
GO

/* =====================================================
   TESTES - CLIENTES
   ===================================================== */

EXEC Inclui_Cliente
    @RG = '123456789',
    @NOME = 'João Teste',
    @ENDERECO = 'Rua A, 100',
    @BAIRRO = 'Centro',
    @CIDADE = 'Sorocaba',
    @ESTADO = 'SP',
    @TELEFONE = '11999999999',
    @EMAIL = 'joao@teste.com',
    @DATANASCIMENTO = '1990-05-10',
    @SEXO = 'M';
GO

EXEC Mostra_Clientes;
GO

EXEC Mostra_Cliente_Por_ID 1;
GO

EXEC Alterar_Cliente
    @COD_CLIENTE = 1,
    @RG = '987654321',
    @NOME = 'João Alterado',
    @ENDERECO = 'Rua B, 200',
    @BAIRRO = 'Vila Nova',
    @CIDADE = 'Sorocaba',
    @ESTADO = 'SP',
    @TELEFONE = '11888888888',
    @EMAIL = 'joao@novo.com',
    @DATANASCIMENTO = '1990-05-10',
    @SEXO = 'M';
GO

/* =====================================================
   TESTES - FILMES / LOCAÇÃO
   ===================================================== */

SELECT * FROM FILME;
GO

EXEC InserirLocacao
    @ID_CLIENTE = 1,
    @ID_FILME = 2;
GO

SELECT * FROM LOCACOES;
GO

SELECT * FROM FILME;
GO

/* =====================================================
   TESTES - DEVOLUÇÃO
   ===================================================== */

EXEC Devolver_Filme 1;
GO

SELECT * FROM LOCACOES;
GO

SELECT * FROM FILME;
GO

/* =====================================================
   TESTES - CONSULTAS
   ===================================================== */

EXEC MostraClientesAniversarioPorMes 5;
GO

EXEC TodosPorMes;
GO

EXEC SelecionarClienteCidadeIdade
    @CIDADE = 'Sorocaba',
    @IDADE = 40;
GO