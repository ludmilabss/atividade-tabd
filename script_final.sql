-- =================================================================
-- PARTE 1: LIMPEZA E CRIAÇÃO DO AMBIENTE
-- =================================================================
DROP DATABASE IF EXISTS dw_vendas;
CREATE DATABASE dw_vendas;
USE dw_vendas;

-- =================================================================
-- PARTE 2: CRIAÇÃO DAS TABELAS DO DATA WAREHOUSE
-- =================================================================
CREATE TABLE DimTempo ( id_tempo INT PRIMARY KEY AUTO_INCREMENT, data DATE NOT NULL, dia INT NOT NULL, mes INT NOT NULL, ano INT NOT NULL, trimestre INT NOT NULL, dia_semana VARCHAR(20) NOT NULL, UNIQUE KEY uk_data (data) );
CREATE TABLE DimLoja ( id_loja INT PRIMARY KEY AUTO_INCREMENT, nome_loja VARCHAR(150), gerente_loja VARCHAR(255), cidade VARCHAR(100), estado VARCHAR(50) );
CREATE TABLE DimCliente ( id_cliente INT PRIMARY KEY AUTO_INCREMENT, nome_cliente VARCHAR(255), idade INT, genero VARCHAR(50), categoria_cliente VARCHAR(100), cidade VARCHAR(100), estado VARCHAR(50), regiao VARCHAR(50) );
CREATE TABLE DimVendedor ( id_vendedor INT PRIMARY KEY AUTO_INCREMENT, nome_vendedor VARCHAR(255) );
CREATE TABLE DimPromocao ( id_promocao INT PRIMARY KEY AUTO_INCREMENT, nome_promocao VARCHAR(150), tipo_desconto VARCHAR(50), data_inicio DATE, data_fim DATE );
CREATE TABLE DimProduto ( id_produto INT PRIMARY KEY AUTO_INCREMENT, nome_produto VARCHAR(255), categoria_produto VARCHAR(100), pais_origem_fornecedor VARCHAR(100) );
CREATE TABLE FatoVendas ( id_fato_venda INT PRIMARY KEY AUTO_INCREMENT, id_tempo INT, id_loja INT, id_cliente INT, id_vendedor INT, id_promocao INT, id_produto INT, valor_total_venda DECIMAL(10, 2), quantidade_total_vendida INT, margem_lucro_total DECIMAL(10, 2), FOREIGN KEY (id_tempo) REFERENCES DimTempo(id_tempo), FOREIGN KEY (id_loja) REFERENCES DimLoja(id_loja), FOREIGN KEY (id_cliente) REFERENCES DimCliente(id_cliente), FOREIGN KEY (id_vendedor) REFERENCES DimVendedor(id_vendedor), FOREIGN KEY (id_promocao) REFERENCES DimPromocao(id_promocao), FOREIGN KEY (id_produto) REFERENCES DimProduto(id_produto) );

-- =================================================================
-- PARTE 3: CARGA E TRANSFORMAÇÃO (ETL) COM FILTROS CORRIGIDOS
-- =================================================================

-- Carga da DimTempo (IGNORANDO VENDAS COM DATAS INVÁLIDAS)
INSERT INTO DimTempo (data, dia, mes, ano, trimestre, dia_semana)
SELECT DISTINCT
    v.data_venda AS data, DAY(v.data_venda), MONTH(v.data_venda), YEAR(v.data_venda), QUARTER(v.data_venda), DAYNAME(v.data_venda)
FROM crm.vendas v
WHERE TRIM(v.data_venda) RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; 

-- Carga da DimLoja
INSERT INTO DimLoja (nome_loja, gerente_loja, cidade, estado) SELECT DISTINCT l.nome_loja, l.gerente_loja, l.cidade, l.estado FROM crm.lojas l;

-- Carga da DimCliente
INSERT INTO DimCliente (nome_cliente, idade, genero, categoria_cliente, cidade, estado, regiao) SELECT DISTINCT c.nome_cliente, c.idade, CASE WHEN c.genero = 'M' THEN 'Masculino' WHEN c.genero = 'F' THEN 'Feminino' ELSE 'Outro' END, cc.nome_categoria_cliente, l.cidade, l.estado, l.regiao FROM crm.cliente c JOIN crm.categoria_cliente cc ON c.id_categoria_cliente = cc.id_categoria_cliente JOIN crm.localidade l ON c.id_localidade = l.id_localidade;

-- Carga da DimVendedor
INSERT INTO DimVendedor (nome_vendedor) SELECT DISTINCT nome_vendedor FROM crm.vendedor;

-- Carga da DimPromocao (Com a lógica de HEX que já tínhamos)
INSERT INTO DimPromocao (nome_promocao, tipo_desconto, data_inicio, data_fim)
SELECT DISTINCT
    p.nome_promocao, COALESCE(p.tipo_desconto, 'N/A'),
    CASE WHEN TRIM(p.data_inicio) RLIKE '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(TRIM(p.data_inicio), '%d/%m/%Y') ELSE NULL END,
    CASE
        WHEN HEX(p.data_fim) = '4461746120496E76C383C2A16C696461' THEN NULL
        WHEN TRIM(p.data_fim) RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(TRIM(p.data_fim), '%Y-%m-%d')
        ELSE NULL
    END
FROM crm.promocoes p;

-- Carga da DimProduto
INSERT INTO DimProduto (nome_produto, categoria_produto, pais_origem_fornecedor) SELECT DISTINCT COALESCE(p.nome_produto, 'Não Informado'), cp.nome_categoria_produto, COALESCE(f.pais_origem, 'Não Informado') FROM crm.produto p JOIN crm.categoria_produto cp ON p.id_categoria_produto = cp.id_categoria_produto LEFT JOIN crm.produto_fornecedor pf ON p.id_produto = pf.id_produto LEFT JOIN crm.fornecedores f ON pf.id_fornecedor = f.id_fornecedor;

-- Carga da FatoVendas (IGNORANDO VENDAS COM DATAS INVÁLIDAS)
INSERT INTO FatoVendas (id_tempo, id_loja, id_cliente, id_vendedor, id_promocao, id_produto, valor_total_venda, quantidade_total_vendida, margem_lucro_total)
SELECT
    t.id_tempo, l.id_loja, c.id_cliente, v.id_vendedor, p.id_promocao, pr.id_produto,
    (iv.preco_venda * iv.qtd_vendida), iv.qtd_vendida, ((iv.preco_venda - pf.custo_compra_unitario) * iv.qtd_vendida)
FROM crm.vendas vv
JOIN crm.item_vendas iv ON vv.id_venda = iv.id_venda
JOIN DimTempo t ON t.data = vv.data_venda
JOIN DimLoja l ON l.id_loja = vv.id_loja
JOIN DimCliente c ON c.id_cliente = vv.id_cliente
JOIN DimVendedor v ON v.id_vendedor = vv.id_vendedor
LEFT JOIN DimPromocao p ON p.id_promocao = iv.id_promocao_aplicada
JOIN DimProduto pr ON pr.id_produto = iv.id_produto
LEFT JOIN crm.produto_fornecedor pf ON pf.id_produto = iv.id_produto
WHERE TRIM(vv.data_venda) RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND iv.qtd_vendida > 0;