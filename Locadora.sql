-- ============================================================
-- TABELAS BASE
-- ============================================================

CREATE TABLE Cliente (
    ID_Cliente      INT           IDENTITY(1,1) PRIMARY KEY,
    Nome            NVARCHAR(100) NOT NULL,
    Data_Nascimento DATE          NOT NULL,
    Cidade          NVARCHAR(50)  NOT NULL
);

CREATE TABLE Filme (
    ID_Filme  INT           IDENTITY(1,1) PRIMARY KEY,
    Titulo    NVARCHAR(100) NOT NULL,
    Status    VARCHAR(10)   NOT NULL DEFAULT 'Disponivel'
);

CREATE TABLE Locacao (
    ID_Locacao     INT  IDENTITY(1,1) PRIMARY KEY,
    ID_Cliente     INT  NOT NULL REFERENCES Cliente(ID_Cliente),
    ID_Filme       INT  NOT NULL REFERENCES Filme(ID_Filme),
    Data_Locacao   DATE NOT NULL DEFAULT GETDATE(),
    Data_Devolucao DATE NULL
);
GO


-- ============================================================
-- EXERCÍCIO 1-A: Incluir_Cliente
-- ============================================================
CREATE OR ALTER PROCEDURE Incluir_Cliente
    @Nome            NVARCHAR(100),
    @Data_Nascimento DATE,
    @Cidade          NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Cliente (Nome, Data_Nascimento, Cidade)
    VALUES (@Nome, @Data_Nascimento, @Cidade);

    PRINT 'Cliente incluído com sucesso. ID: ' + CAST(SCOPE_IDENTITY() AS VARCHAR);
END;
GO


-- ============================================================
-- EXERCÍCIO 1-B: Alterar_Cliente
-- ============================================================
CREATE OR ALTER PROCEDURE Alterar_Cliente
    @ID_Cliente      INT,
    @Nome            NVARCHAR(100),
    @Data_Nascimento DATE,
    @Cidade          NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE ID_Cliente = @ID_Cliente)
    BEGIN
        RAISERROR('Cliente não encontrado.', 16, 1);
        RETURN;
    END

    UPDATE Cliente
    SET Nome            = @Nome,
        Data_Nascimento = @Data_Nascimento,
        Cidade          = @Cidade
    WHERE ID_Cliente = @ID_Cliente;

    PRINT 'Cliente alterado com sucesso.';
END;
GO


-- ============================================================
-- EXERCÍCIO 1-C: Selecionar_Cliente
-- (sem parâmetro = todos; com ID = um específico)
-- ============================================================
CREATE OR ALTER PROCEDURE Selecionar_Cliente
    @ID_Cliente INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ID_Cliente, Nome, Data_Nascimento, Cidade
    FROM   Cliente
    WHERE  (@ID_Cliente IS NULL OR ID_Cliente = @ID_Cliente)
    ORDER BY Nome;
END;
GO


-- ============================================================
-- EXERCÍCIO 1-D: Excluir_Cliente
-- ============================================================
CREATE OR ALTER PROCEDURE Excluir_Cliente
    @ID_Cliente INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE ID_Cliente = @ID_Cliente)
    BEGIN
        RAISERROR('Cliente não encontrado.', 16, 1);
        RETURN;
    END

    DELETE FROM Cliente WHERE ID_Cliente = @ID_Cliente;

    PRINT 'Cliente excluído com sucesso.';
END;
GO


-- ============================================================
-- EXERCÍCIO 2: proc_Aniversariantes_Mes
-- Recebe o número do mês e lista Nome + Dia
-- ============================================================
CREATE OR ALTER PROCEDURE proc_Aniversariantes_Mes
    @Mes INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Nome,
        DAY(Data_Nascimento) AS Dia
    FROM  Cliente
    WHERE MONTH(Data_Nascimento) = @Mes
    ORDER BY DAY(Data_Nascimento);
END;
GO


-- ============================================================
-- EXERCÍCIO 3: Resumo_Aniversariantes
-- Contagem por mês — meses sem aniversariantes mostram 0
-- ============================================================
CREATE OR ALTER PROCEDURE Resumo_Aniversariantes
AS
BEGIN
    SET NOCOUNT ON;

    WITH Meses AS (
        SELECT 1 AS Mes UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL
        SELECT 4        UNION ALL SELECT 5  UNION ALL SELECT 6  UNION ALL
        SELECT 7        UNION ALL SELECT 8  UNION ALL SELECT 9  UNION ALL
        SELECT 10       UNION ALL SELECT 11 UNION ALL SELECT 12
    )
    SELECT
        M.Mes,
        DATENAME(MONTH, DATEFROMPARTS(2000, M.Mes, 1)) AS Nome_Mes,
        COUNT(C.ID_Cliente)                             AS Total_Aniversariantes
    FROM  Meses M
    LEFT JOIN Cliente C ON MONTH(C.Data_Nascimento) = M.Mes
    GROUP BY M.Mes
    ORDER BY M.Mes;
END;
GO


-- ============================================================
-- EXERCÍCIO 4: Clientes_Por_Cidade_Idade
-- Lista clientes de uma cidade com idade <= ao valor informado
-- Colunas: [Nome do Cliente] [Data Nascimento] [Idade]
-- ============================================================
CREATE OR ALTER PROCEDURE Clientes_Por_Cidade_Idade
    @Cidade    NVARCHAR(50),
    @Idade_Max INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Nome            AS [Nome do Cliente],
        Data_Nascimento AS [Data Nascimento],
        DATEDIFF(YEAR, Data_Nascimento, GETDATE())
        - CASE
            WHEN MONTH(Data_Nascimento) > MONTH(GETDATE())
              OR (    MONTH(Data_Nascimento) = MONTH(GETDATE())
                  AND DAY(Data_Nascimento)   > DAY(GETDATE()))
            THEN 1 ELSE 0
          END            AS [Idade]
    FROM  Cliente
    WHERE Cidade = @Cidade
      AND DATEDIFF(YEAR, Data_Nascimento, GETDATE())
          - CASE
              WHEN MONTH(Data_Nascimento) > MONTH(GETDATE())
                OR (    MONTH(Data_Nascimento) = MONTH(GETDATE())
                    AND DAY(Data_Nascimento)   > DAY(GETDATE()))
              THEN 1 ELSE 0
            END <= @Idade_Max
    ORDER BY Nome;
END;
GO


-- ============================================================
-- EXERCÍCIO 5: Incluir_Locacao
-- Parâmetros: ID_Cliente, ID_Filme
-- Data_Locacao vem do sistema (GETDATE)
-- Após inserir, marca o filme como 'alugado'
-- ============================================================
CREATE OR ALTER PROCEDURE Incluir_Locacao
    @ID_Cliente INT,
    @ID_Filme   INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE ID_Cliente = @ID_Cliente)
    BEGIN
        RAISERROR('Cliente não encontrado.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Filme WHERE ID_Filme = @ID_Filme)
    BEGIN
        RAISERROR('Filme não encontrado.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Filme WHERE ID_Filme = @ID_Filme AND Status = 'alugado')
    BEGIN
        RAISERROR('Filme já está alugado no momento.', 16, 1);
        RETURN;
    END

    INSERT INTO Locacao (ID_Cliente, ID_Filme, Data_Locacao, Data_Devolucao)
    VALUES (@ID_Cliente, @ID_Filme, GETDATE(), NULL);

    UPDATE Filme
    SET    Status = 'alugado'
    WHERE  ID_Filme = @ID_Filme;

    PRINT 'Locação registrada com sucesso. ID: ' + CAST(SCOPE_IDENTITY() AS VARCHAR);
END;
GO


-- ============================================================
-- EXERCÍCIO 6: Devolver_Filme
-- Parâmetro: ID_Locacao
-- Registra Data_Devolucao = GETDATE() e volta Status = 'Disponivel'
-- ============================================================
CREATE OR ALTER PROCEDURE Devolver_Filme
    @ID_Locacao INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID_Filme INT;

    SELECT @ID_Filme = ID_Filme
    FROM   Locacao
    WHERE  ID_Locacao = @ID_Locacao;

    IF @ID_Filme IS NULL
    BEGIN
        RAISERROR('Locação não encontrada.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM Locacao
        WHERE  ID_Locacao = @ID_Locacao
          AND  Data_Devolucao IS NOT NULL
    )
    BEGIN
        RAISERROR('Este filme já foi devolvido anteriormente.', 16, 1);
        RETURN;
    END

    UPDATE Locacao
    SET    Data_Devolucao = GETDATE()
    WHERE  ID_Locacao = @ID_Locacao;

    UPDATE Filme
    SET    Status = 'Disponivel'
    WHERE  ID_Filme = @ID_Filme;

    PRINT 'Devolução registrada com sucesso.';
END;
GO


-- ============================================================
-- TESTES
-- ============================================================

-- Popula clientes
EXEC Incluir_Cliente 'Ana Silva',      '1990-03-15', 'São Paulo';
EXEC Incluir_Cliente 'Bruno Costa',    '1985-03-22', 'Rio de Janeiro';
EXEC Incluir_Cliente 'Carla Souza',    '1992-07-10', 'São Paulo';
EXEC Incluir_Cliente 'Diego Martins',  '2000-11-05', 'Curitiba';
EXEC Incluir_Cliente 'Elena Ferreira', '1995-03-01', 'São Paulo';
EXEC Incluir_Cliente 'Fabio Lima',     '1988-07-30', 'São Paulo';

-- Popula filmes
INSERT INTO Filme (Titulo) VALUES ('Matrix');
INSERT INTO Filme (Titulo) VALUES ('Interestelar');
INSERT INTO Filme (Titulo) VALUES ('O Poderoso Chefão');

-- Ex 1: CRUD
EXEC Selecionar_Cliente;                                              -- todos
EXEC Alterar_Cliente 1, 'Ana Paula Silva', '1990-03-15', 'São Paulo'; -- altera
EXEC Selecionar_Cliente 1;                                            -- um só
EXEC Excluir_Cliente 4;                                               -- exclui Diego
EXEC Selecionar_Cliente;                                              -- confirma exclusão

-- Ex 2: Aniversariantes de março (mês 3)
EXEC proc_Aniversariantes_Mes 3;

-- Ex 3: Resumo por mês
EXEC Resumo_Aniversariantes;

-- Ex 4: Clientes de SP com até 35 anos
EXEC Clientes_Por_Cidade_Idade 'São Paulo', 35;

-- Ex 5: Locar filme
EXEC Incluir_Locacao 1, 1;
SELECT ID_Filme, Titulo, Status FROM Filme WHERE ID_Filme = 1; -- deve mostrar 'alugado'
SELECT * FROM Locacao;

-- Teste de rejeição: tentar alugar o mesmo filme novamente
EXEC Incluir_Locacao 2, 1; -- deve retornar erro

-- Ex 6: Devolver filme
EXEC Devolver_Filme 1;
SELECT ID_Filme, Titulo, Status FROM Filme WHERE ID_Filme = 1; -- deve mostrar 'Disponivel'
SELECT * FROM Locacao WHERE ID_Locacao = 1;                    -- deve ter Data_Devolucao preenchida

-- Teste de rejeição: devolver novamente
EXEC Devolver_Filme 1; -- deve retornar erro