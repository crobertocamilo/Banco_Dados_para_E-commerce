USE ecommerce3;


SELECT
  COUNT(*) AS Total_Clientes,
  COUNT(CASE WHEN tipoCliente = 'PJ' THEN 1 ELSE NULL END) AS Total_Clientes_PJ,
  COUNT(CASE WHEN tipoCliente = 'PF' THEN 1 ELSE NULL END) AS Total_Clientes_PF
FROM CLIENTE;

select idCliente, count(*) from PEDIDO group by idCliente;

desc PEDIDO;

select idCliente, p.idPedido, p.statusPedido from CLIENTE as c join PEDIDO as p on c.idCliente = p.idCliente; 

select count(distinct c.idCliente)/(count (*) from PEDIDO) from CLIENTE as c join PEDIDO as p on c.idCliente = p.idCliente; 

SELECT AVG(pedidos_por_cliente) AS Media_Pedidos_Por_Cliente
FROM (
    SELECT c.idCliente, COUNT(*) AS pedidos_por_cliente
    FROM CLIENTE AS c
    JOIN PEDIDO AS p ON c.idCliente = p.idCliente
    GROUP BY c.idCliente
) AS pedidos_por_cliente_distinto;

select count(distinct c.idCliente) from CLIENTE as c join PEDIDO as p on c.idCliente = p.idCliente where p.statusPedido = 'Cancelado';