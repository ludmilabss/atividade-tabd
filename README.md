# Relatório de Implementação do Processo ETL  
**Disciplina:** Tópicos Avançados em Banco de Dados  
**Projeto:** Data Warehouse de Vendas – Global Retail  
**Equipe:** Divaldo Verçosa e Ludmila Barbosa

---

## 1. Descrição do Projeto

Este projeto implementa um processo completo de **ETL (Extração, Transformação e Carga)** para alimentar um Data Warehouse (DW) de vendas para a empresa fictícia "Global Retail". O objetivo é migrar dados de um sistema transacional de origem (OLTP), que contém diversas inconsistências, para um ambiente analítico robusto (OLAP), garantindo a integridade, padronização e qualidade dos dados para futuras análises de negócio.

A solução foi desenvolvida utilizando **SQL** para o processo de ETL e **Docker** para orquestrar o ambiente do banco de dados MySQL, garantindo total portabilidade e reprodutibilidade do projeto.

---

## 2. Estrutura do Projeto

- **`docker-compose.yml`**: Ficheiro de configuração do Docker para iniciar o container do serviço MySQL.
- **`script_crm.sql`**: Script SQL para criar a estrutura de tabelas do banco de dados de origem (`crm`).
- **`dados_completos_padronizado.sql`**: Script de inserção dos dados brutos e inconsistentes no banco `crm`.
- **`script_final.sql`**: Script SQL completo que:
    1.  Cria a estrutura do Data Warehouse (`dw_vendas`).
    2.  Executa todo o processo de ETL para limpar, transformar e carregar os dados no DW.

---

## 3. Principais Desafios de ETL e Soluções Implementadas

Durante a implementação, foram identificados e tratados os seguintes problemas de qualidade dos dados:

#### a) Datas Inválidas e Formatos Múltiplos
- **Problema:** As tabelas de origem continham datas em múltiplos formatos (ex: `AAAA-MM-DD`, `DD/MM/AAAA`), valores textuais como `"N/A"`, e o texto `"Data Inválida"`, que por sua vez continha caracteres corrompidos (encoding).
- **Solução:**
  - Foi implementado um filtro com expressões regulares (`RLIKE`) para validar e processar apenas as datas em formatos esperados.
  - Para o caso específico da "Data Inválida" corrompida, a solução final utilizou a função `HEX()` para identificar o padrão hexadecimal exato do dado problemático, criando uma regra de exclusão à prova de falhas.

#### b) Valores Nulos (NULL)
- **Problema:** Campos críticos para a análise, como `nome_produto` e `tipo_desconto`, continham valores nulos.
- **Solução:** A função `COALESCE` foi utilizada para substituir os valores `NULL` por um padrão definido (ex: 'Não Informado' ou 'N/A'), garantindo que todos os campos tenham um valor.

#### c) Padronização de Dados Categóricos
- **Problema:** A coluna `genero` utilizava os caracteres 'M' e 'F'.
- **Solução:** Uma estrutura `CASE ... WHEN` foi aplicada durante a carga para transformar os valores em 'Masculino' e 'Feminino', tornando os dados mais legíveis para os relatórios finais.

#### d) Vendas com Quantidade Negativa
- **Problema:** A tabela `item_vendas` continha registos com quantidade vendida negativa, provavelmente representando estornos ou devoluções.
- **Solução:** Um filtro `WHERE qtd_vendida > 0` foi adicionado na carga da tabela de fatos para garantir que apenas as vendas efetivas fossem consideradas nas métricas.

---

## 4. Instruções para Execução do Projeto

Para recriar e executar este projeto, siga os passos abaixo.

**Pré-requisitos:**
- Docker e Docker Compose instalados na sua máquina.

**Passos:**

1.  **Clone este repositório:**
    ```bash
    git clone [https://github.com/ludmilabss/atividade-tabd.git](https://github.com/ludmilabss/atividade-tabd.git)
    cd atividade-tabd
    ```

2.  **Inicie o container do MySQL:**
    Este comando irá baixar a imagem do MySQL e iniciar o serviço em segundo plano.
    ```bash
    docker-compose up -d
    ```

3.  **Aguarde o MySQL ficar pronto:**
    É crucial esperar alguns segundos para o banco de dados inicializar completamente. Verifique os logs com o comando abaixo e aguarde até ver a mensagem `ready for connections`. Depois, pode sair com `Ctrl+C`.
    ```bash
    docker logs -f mysql_db_tabd
    ```

4.  **Execute a carga dos dados de origem (OLTP):**
    Estes comandos criam e populam o banco `crm` com os dados brutos.
    ```bash
    # Cria a estrutura do crm
    docker exec -i mysql_db_tabd mysql -uroot -proot crm < script_crm.sql

    # Insere os dados brutos no crm
    docker exec -i mysql_db_tabd mysql -uroot -proot crm < dados_completos_padronizado.sql
    ```

5.  **Execute o script final de criação do DW e ETL:**
    Este único script irá criar o DW `dw_vendas`, limpar, transformar e carregar todos os dados.
    ```bash
    docker exec -i mysql_db_tabd mysql -uroot -proot < script_final.sql
    ```

Ao final deste último passo, o seu Data Warehouse estará pronto para ser consultado.
