
-- Tabelas base
CREATE TABLE Produto (
    ID_Produto  INT          IDENTITY(1,1) PRIMARY KEY,
    Descricao   NVARCHAR(40) NOT NULL,
    Unidade     VARCHAR(2)   NOT NULL
);

CREATE TABLE Saldo (
    ID_Produto  INT           NOT NULL REFERENCES Produto(ID_Produto),
    Saldo_Atual DECIMAL(15,4) NOT NULL DEFAULT 0
);

CREATE TABLE Venda (
    ID_Venda        INT           IDENTITY(1,1) PRIMARY KEY,
    Data_Venda      DATE          NOT NULL DEFAULT GETDATE(),
    ID_Cliente      INT           NOT NULL,
    ID_Produto      INT           NOT NULL REFERENCES Produto(ID_Produto),
    QTD_Venda       INT           NOT NULL,
    Valor_Total     DECIMAL(15,2) NOT NULL,
    Numero_Parcelas INT           NOT NULL DEFAULT 1,
    n_parcelas      INT           NOT NULL DEFAULT 1   -- já inclusa aqui, sem precisar de ALTER depois
);

select *from Feriados_Fixos

CREATE TABLE Compra (
    ID_Compra       INT           IDENTITY(1,1) PRIMARY KEY,
    Data_Compra     DATE          NOT NULL DEFAULT GETDATE(),
    ID_Cliente      INT           NOT NULL,
    ID_Produto      INT           NOT NULL REFERENCES Produto(ID_Produto),
    QTD_Compra      INT           NOT NULL,
    Valor_Total     DECIMAL(15,2) NOT NULL,
    Numero_Parcelas INT           NOT NULL DEFAULT 1
);

CREATE TABLE Feriados_Fixos (
    Dia       TINYINT      NOT NULL,
    Mes       TINYINT      NOT NULL,
    Descricao NVARCHAR(50) NOT NULL,
    PRIMARY KEY (Dia, Mes)
);

CREATE TABLE Feriados_Do_Ano (
    Data_Feriado DATE         NOT NULL PRIMARY KEY,
    Descricao    NVARCHAR(50) NOT NULL
);

CREATE TABLE Contas_A_Receber (
    ID_Receber      INT   IDENTITY(1,1) PRIMARY KEY,
    ID_Venda        INT   NOT NULL REFERENCES Venda(ID_Venda),
    Num_Parcela     INT   NOT NULL,
    Data_Vencimento DATE  NOT NULL,
    Valor_Parcela   MONEY NOT NULL,
    Data_Pagamento  DATE  NULL
);
GO

-- Feriados fixos
INSERT INTO Feriados_Fixos VALUES
(1,  1,  'Confraternização Universal'),
(21, 4,  'Tiradentes'),
(1,  5,  'Dia do Trabalho'),
(7,  9,  'Independência do Brasil'),
(12, 10, 'Nossa Sra. Aparecida'),
(2,  11, 'Finados'),
(15, 11, 'Proclamação da República'),
(25, 12, 'Natal');

-- Feriados móveis 2025
INSERT INTO Feriados_Do_Ano VALUES
('2025-03-03', 'Carnaval (segunda)'),
('2025-03-04', 'Carnaval (terça)'),
('2025-04-18', 'Sexta-Feira Santa'),
('2025-06-19', 'Corpus Christi');
GO

-- Exercício 1: trigger subtrai saldo na venda
CREATE OR ALTER TRIGGER TR_Venda_Subtrai_Saldo
ON Venda
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET    S.Saldo_Atual = S.Saldo_Atual - I.QTD_Venda
    FROM   Saldo S
    INNER JOIN inserted I ON I.ID_Produto = S.ID_Produto;

    IF EXISTS (
        SELECT 1 FROM Saldo S
        INNER JOIN inserted I ON I.ID_Produto = S.ID_Produto
        WHERE S.Saldo_Atual < 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Saldo insuficiente para um ou mais produtos.', 16, 1);
    END
END;
GO

-- Exercício 2: trigger soma saldo na compra
CREATE OR ALTER TRIGGER TR_Compra_Soma_Saldo
ON Compra
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET    S.Saldo_Atual = S.Saldo_Atual + I.QTD_Compra
    FROM   Saldo S
    INNER JOIN inserted I ON I.ID_Produto = S.ID_Produto;
END;
GO

-- Exercício 3: função dia útil
CREATE OR ALTER FUNCTION FN_ProximoDiaUtil (@Data DATE)
RETURNS DATE
AS
BEGIN
    WHILE (
        DATEPART(WEEKDAY, @Data) IN (1, 7)
        OR EXISTS (
            SELECT 1 FROM Feriados_Fixos
            WHERE Dia = DAY(@Data) AND Mes = MONTH(@Data)
        )
        OR EXISTS (
            SELECT 1 FROM Feriados_Do_Ano
            WHERE Data_Feriado = @Data
        )
    )
    BEGIN
        SET @Data = DATEADD(DAY, 1, @Data);
    END
    RETURN @Data;
END;
GO

-- Exercício 3: trigger gera parcelas
CREATE OR ALTER TRIGGER TR_Venda_Gera_Parcelas
ON Venda
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @ID_Venda     INT,
        @ValorTotal   MONEY,
        @nParcelas    INT,
        @ValorParcela MONEY,
        @DataBase     DATE,
        @DataVenc     DATE,
        @i            INT;

    DECLARE cur CURSOR FOR
        SELECT ID_Venda, Valor_Total, n_parcelas, Data_Venda
        FROM   inserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @ID_Venda, @ValorTotal, @nParcelas, @DataBase;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ValorParcela = ROUND(@ValorTotal / @nParcelas, 2);
        SET @i = 1;

        WHILE @i <= @nParcelas
        BEGIN
            SET @DataVenc = dbo.FN_ProximoDiaUtil(DATEADD(MONTH, @i, @DataBase));

            INSERT INTO Contas_A_Receber
                (ID_Venda, Num_Parcela, Data_Vencimento, Valor_Parcela, Data_Pagamento)
            VALUES
                (@ID_Venda, @i, @DataVenc, @ValorParcela, NULL);

            SET @i = @i + 1;
        END

        FETCH NEXT FROM cur INTO @ID_Venda, @ValorTotal, @nParcelas, @DataBase;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- =====================
-- TESTES
-- =====================

INSERT INTO Produto (Descricao, Unidade) VALUES ('Caneta Azul', 'pc');
INSERT INTO Produto (Descricao, Unidade) VALUES ('Caderno', 'un');

INSERT INTO Saldo (ID_Produto, Saldo_Atual) VALUES (1, 100);
INSERT INTO Saldo (ID_Produto, Saldo_Atual) VALUES (2, 50);

-- Teste 1: venda subtrai saldo (100 -> 90)
INSERT INTO Venda (Data_Venda, ID_Cliente, ID_Produto, QTD_Venda, Valor_Total, Numero_Parcelas, n_parcelas)
VALUES (GETDATE(), 1, 1, 10, 10.00, 3, 3);
SELECT * FROM Saldo;
SELECT * FROM Contas_A_Receber;

-- Teste 2: compra soma saldo (90 -> 110)
INSERT INTO Compra (Data_Compra, ID_Cliente, ID_Produto, QTD_Compra, Valor_Total, Numero_Parcelas)
VALUES (GETDATE(), 1, 1, 20, 300.00, 1);
SELECT * FROM Saldo;

-- Teste 3: saldo negativo deve dar erro
INSERT INTO Venda (Data_Venda, ID_Cliente, ID_Produto, QTD_Venda, Valor_Total, Numero_Parcelas, n_parcelas)
VALUES (GETDATE(), 1, 1, 200, 500.00, 1, 1);