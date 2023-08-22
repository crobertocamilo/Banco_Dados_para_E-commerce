SHOW DATABASES;

CREATE SCHEMA IF NOT EXISTS ecommerce3 DEFAULT CHARACTER SET utf8 ;
USE ecommerce3;

-- Tabela CLIENTE_PF para pessoas físicas (com CPF)
CREATE TABLE IF NOT EXISTS CLIENTE_PF (
  cpf CHAR(11) NOT NULL,
  primeiroNome VARCHAR(25) NOT NULL,
  ultimoNome VARCHAR(15) NOT NULL,
  dataNascimento DATE NOT NULL,
  endereco VARCHAR(45) NOT NULL,
  cep CHAR(8) NOT NULL,
  municipio VARCHAR(30) NOT NULL,
  uf CHAR(2) NOT NULL,
  pais VARCHAR(25) NOT NULL,
  PRIMARY KEY (cpf),
  UNIQUE INDEX cpf_UNIQUE (cpf ASC));
  
-- Tabela CLIENTE_PJ para cliente empresariais (com CNPJ)
CREATE TABLE IF NOT EXISTS CLIENTE_PJ (
  cnpj CHAR(14) NOT NULL,
  razaoSocial VARCHAR(35) NOT NULL,
  nomeFantasia VARCHAR(35) NOT NULL,
  dataFundacao DATE NULL,
  endereco VARCHAR(45) NOT NULL,
  cep CHAR(8) NOT NULL,
  municipio VARCHAR(30) NOT NULL,
  uf CHAR(2) NOT NULL,
  pais VARCHAR(25) NOT NULL,
  UNIQUE INDEX cnpj_UNIQUE (cnpj ASC),
  UNIQUE INDEX razaoSocial_UNIQUE (razaoSocial ASC),
  PRIMARY KEY (cnpj));
    
-- Tabela CLIENTE: agrega todos os cliente numa única tabela, independente se pessoa ou empresa
-- Um cliente deve ser PF OU PJ, nunca os dois, o que é garantido pelo trigger a seguir
-- Cada CPF e cada CNJP deve ter uma única entrada na tabela CLIENTE (para evitar que um mesmo cliente tenha duas registros/contas)
CREATE TABLE IF NOT EXISTS CLIENTE (
  idCliente INT NOT NULL auto_increment,
  cpf CHAR(11) NULL,
  cnpj CHAR(14) NULL,
  tipoCliente ENUM('PF', 'PJ') NOT NULL,
  PRIMARY KEY (idCliente),
  INDEX fk_CLIENTE_1_idx (cpf ASC),
  CONSTRAINT fk_CLIENTE_1
    FOREIGN KEY (cpf)
    REFERENCES CLIENTE_PF (cpf)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT fk_CLIENTE_2
    FOREIGN KEY (cnpj)
    REFERENCES CLIENTE_PJ (cnpj)
    ON DELETE NO ACTION
    ON UPDATE CASCADE);
    
-- Este trigger impede que um mesmo cliente seja cadastrado com CPF e CNPJ, deve ter um ou outro.
DELIMITER //
CREATE TRIGGER ClientePF_ou_PJ_somente
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
  IF (NEW.tipoCliente = 'PF' AND NEW.cnpj IS NOT NULL) OR
     (NEW.tipoCliente = 'PJ' AND NEW.cpf IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Um cliente deve ser cadastrado como PF ou PJ, não ambos';
  END IF;
END;
//
DELIMITER ;

-- Este trigger pesquisa se um CPF é único na tabela CLIENTE
DELIMITER //
CREATE TRIGGER verifica_cpf_duplicado
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
    DECLARE cpf_count INT;
    SET cpf_count = (SELECT COUNT(*) FROM CLIENTE WHERE cpf = NEW.cpf);

    IF cpf_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CPF duplicado! Pesquise os clientes já cadastrados.';
    END IF;
END;
//
DELIMITER ;

-- Este trigger pesquisa se um CNPJ é único na tabela CLIENTE
DELIMITER //
CREATE TRIGGER verifica_cnpj_duplicado
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
    DECLARE cnpj_count INT;
    SET cnpj_count = (SELECT COUNT(*) FROM CLIENTE WHERE cnpj = NEW.cnpj);

    IF cnpj_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CNPJ duplicado! Pesquise os clientes já cadastrados.';
    END IF;
END;
//
DELIMITER ;

-- Tabela PEDIDO
CREATE TABLE IF NOT EXISTS PEDIDO (
  idPedido INT NOT NULL AUTO_INCREMENT,
  idCliente INT NOT NULL,
  statusPedido ENUM('Aprovado','Cancelado', 'Em Processamento', 'Enviado', 'Entregue') NOT NULL,
  dataCompra DATE NOT NULL,
  ultimaAtualizacao DATETIME NOT NULL,
  descricao VARCHAR(255) NULL,
  PRIMARY KEY (idPedido),
  UNIQUE INDEX idPedido_UNIQUE (idPedido ASC),
  INDEX fk_PEDIDO_1_idx (idCliente ASC),
  CONSTRAINT fk_PEDIDO_1
    FOREIGN KEY (idCliente)
    REFERENCES CLIENTE (idCliente)
    ON DELETE NO ACTION
    ON UPDATE CASCADE);
        
-- Tabela PAGAMENTO    
-- Tabela dependente de PEDIDO, com informações específicas sobre pagamentos.
CREATE TABLE IF NOT EXISTS PAGAMENTO (
  idPagamento INT NOT NULL AUTO_INCREMENT,
  idPedido INT NOT NULL,
  formaPagamento ENUM('PIX', 'Cartão Crédito', 'Boleto', 'Transferência Bancária') NOT NULL,
  statusPagamento ENUM('Aprovado', 'Em processamento', 'Aguardando', 'Cancelado') NOT NULL,
  ultimaAtualizacao DATETIME NOT NULL,
  PRIMARY KEY (idPagamento),
  UNIQUE INDEX idPagamento_UNIQUE (idPagamento ASC),
  UNIQUE INDEX idPedido_UNIQUE (idPedido ASC),
  CONSTRAINT fk_PAGAMENTO_1
    FOREIGN KEY (idPedido)
    REFERENCES PEDIDO (idPedido)
    ON DELETE CASCADE
    ON UPDATE CASCADE);
    
-- Tabela FORNECEDOR
CREATE TABLE IF NOT EXISTS FORNECEDOR (
  idFornecedor INT NOT NULL AUTO_INCREMENT,
  razaoSocial VARCHAR(35) NOT NULL,
  nomeFantasia VARCHAR(35) NOT NULL,
  cnpj CHAR(14) NOT NULL,
  dataFundacao DATE NULL,
  endereco VARCHAR(45) NOT NULL,
  cep CHAR(8) NOT NULL,
  municipio VARCHAR(30) NOT NULL,
  uf CHAR(2) NOT NULL,
  pais VARCHAR(25) NOT NULL,
  PRIMARY KEY (idFornecedor),
  UNIQUE INDEX idClientes_UNIQUE (idFornecedor ASC),
  UNIQUE INDEX cnpj_UNIQUE (cnpj ASC),
  UNIQUE INDEX razaoSocial_UNIQUE (razaoSocial ASC));

-- Tabela PRODUTO
CREATE TABLE IF NOT EXISTS PRODUTO (
  idProduto INT NOT NULL AUTO_INCREMENT,
  nomeProduto VARCHAR(30) NOT NULL,
  descricao VARCHAR(255) NULL,
  paraCriancas TINYINT(1) NOT NULL DEFAULT 0,
  precoUnitarioVenda FLOAT NOT NULL,
  categoria ENUM('Vestuario', 'Eletroeletronicos', 'Eletrodomesticos','Livros', 'Papelaria', 'Moveis', 'Outros') NOT NULL DEFAULT 'Outros',
  peso_kg FLOAT NULL,
  dimensoes ENUM('Micro','Pequeno','Normal','Grande','Volumoso') NULL default 'Normal',
  avaliacao FLOAT NULL,
  PRIMARY KEY (idProduto));
  
-- Tabela PRODUTO_FORNECEDOR
-- Um mesmo produto pode ter vários fornecedores, mas para cada fornecedor, o produto deve ter uma entrada nesta tabela.
CREATE TABLE IF NOT EXISTS PRODUTO_FORNECEDOR (
  idPRODUTO INT NOT NULL,
  idFornecedor INT NOT NULL,
  estoque INT NOT NULL,
  valorUnitarioCompra FLOAT NOT NULL,
  observacao VARCHAR(255) NULL,
  PRIMARY KEY (idPRODUTO, idFornecedor),
  INDEX fk_PRODUTO_FORNECEDOR_2_idx (idFornecedor ASC),
  CONSTRAINT fk_PRODUTO_FORNECEDOR_1
    FOREIGN KEY (idPRODUTO)
    REFERENCES PRODUTO (idProduto)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT fk_PRODUTO_FORNECEDOR_2
    FOREIGN KEY (idFornecedor)
    REFERENCES FORNECEDOR (idFornecedor)
    ON DELETE NO ACTION
    ON UPDATE CASCADE);
    
-- Tabela ITEM_PEDIDO 
-- Um pedido pode ser composto por um ou vários produtos, cada um com quantidade própria.
CREATE TABLE IF NOT EXISTS ITEM_PEDIDO (
  idPedido INT NOT NULL,
  idProduto INT NOT NULL,
  quantidade INT NOT NULL DEFAULT 1,
  PRIMARY KEY (idPedido, idProduto),
  INDEX fk_ITEM_PEDIDO_1_idx (idProduto ASC),
  CONSTRAINT fk_ITEM_PEDIDO_1
    FOREIGN KEY (idProduto)
    REFERENCES PRODUTO (idProduto)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT fk_ITEM_PEDIDO_2
    FOREIGN KEY (idPedido)
    REFERENCES PEDIDO (idPedido)
    ON DELETE NO ACTION
    ON UPDATE CASCADE);
    
SHOW TABLES;






