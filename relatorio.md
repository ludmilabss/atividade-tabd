# Relatório de Implementação do Processo ETL  
**Disciplina:** Tópicos Avançados em Banco de Dados  
**Projeto:** Data Warehouse de Vendas – Global Retail  
**Equipe:** [Preencher nomes dos integrantes]

---

## 1. Descrição do Projeto

Este projeto implementa um processo completo de ETL (Extração, Transformação e Carga) para alimentar um Data Warehouse (DW) de vendas da Global Retail. O objetivo é migrar dados de um sistema transacional (OLTP) com diversas inconsistências para um ambiente analítico (OLAP), garantindo integridade, padronização e qualidade dos dados.

---

## 2. Estrutura do Projeto

- **docker-compose.yml:** Orquestração do ambiente de banco de dados.
- **script_crm.sql:** Criação do banco de dados de origem (OLTP) e suas tabelas.
- **dados_completos_padronizado.sql:** População do banco OLTP com dados reais e inconsistentes.
- **script_final.sql:** Criação do Data Warehouse (DW) e implementação do processo ETL (extração, transformação e carga dos dados).

---

## 3. Principais Desafios e Tratamento de Inconsistências

Durante a implementação do ETL, foram identificados e tratados os seguintes problemas de qualidade dos dados:

### **a) Datas em Formatos Inválidos**
- **Problema:** Datas em formatos diferentes ou inválidos (ex: '2023-12-01', '01/12/2023', valores HEX).
- **Solução:**  
  - Utilização de expressões regulares (RLIKE) para filtrar apenas datas válidas.
  - Conversão de formatos diferentes usando `STR_TO_DATE`.
  - Valores HEX específicos tratados como NULL.

### **b) Valores Nulos e Não Informados**
- **Problema:** Campos como nome de produto, país de origem, tipo de desconto, etc., com valores nulos.
- **Solução:**  
  - Uso de `COALESCE` para substituir nulos por valores padrão como 'Não Informado' ou 'N/A'.

### **c) Padronização de Gênero**
- **Problema:** Gênero informado como 'M', 'F' ou outros valores.
- **Solução:**  
  - Uso de `CASE` para padronizar para 'Masculino', 'Feminino' ou 'Outro'.

### **d) Chaves Estrangeiras e Integridade Referencial**
- **Problema:** Possibilidade de registros órfãos ou inconsistentes.
- **Solução:**  
  - Carga das tabelas de dimensão antes da tabela fato.
  - Uso de joins e filtros para garantir apenas registros válidos.

### **e) Quantidade Vendida Inválida**
- **Problema:** Vendas com quantidade menor ou igual a zero.
- **Solução:**  
  - Filtro explícito no ETL para ignorar essas vendas.

---

## 4. Descrição do Fluxo de Trabalho do ETL

1. **Preparação do Ambiente**
   - Subida do banco de dados via Docker.
   - Execução dos scripts de criação e carga do banco OLTP.

2. **Criação do Data Warehouse**
   - Execução do script de criação das tabelas de dimensões e fatos no DW.

3. **Processo ETL**
   - **Extração:** Leitura dos dados das tabelas do OLTP.
   - **Transformação:**  
     - Limpeza e padronização dos dados conforme descrito acima.
     - Enriquecimento dos dados via joins entre tabelas.
   - **Carga:**  
     - Inserção dos dados tratados nas tabelas de dimensão.
     - Inserção dos dados na tabela fato, utilizando as chaves surrogadas das dimensões.

---

## 5. Resumo das Tabelas Criadas

- **Dimensões:**  
  - DimTempo, DimLoja, DimCliente, DimVendedor, DimPromocao, DimProduto
- **Fato:**  
  - FatoVendas

---

## 6. Considerações Finais

O processo ETL foi implementado inteiramente em SQL, garantindo robustez e clareza no tratamento das inconsistências dos dados. O uso de Docker facilita a replicação do ambiente. Todos os scripts necessários para a criação, carga e transformação dos dados estão presentes no repositório.

---

## 7. Instruções para Execução

1. Suba o ambiente com Docker Compose:
   ```bash
   docker-compose up -d
   ```
2. Execute os scripts na seguinte ordem:
   1. `script_crm.sql` (criação do OLTP)
   2. `dados_completos_padronizado.sql` (população do OLTP)
   3. `script_final.sql` (criação do DW e ETL)

---

