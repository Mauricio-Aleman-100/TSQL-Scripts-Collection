Cálculo de Usuarios Activos Mensuales - Facebook User Actions
Descripción:
Este proyecto presenta una consulta SQL diseñada para calcular el número de Usuarios Activos Mensuales (MAU) durante julio de 2022, a partir de un registro de acciones de usuarios en una red social (como “sign-in”, “like” o “comment”).

Un usuario activo se define como aquel que ha realizado al menos una acción en dos meses consecutivos (el mes actual y el mes anterior). 
Esta métrica es fundamental para medir la retención de usuarios y evaluar la salud del producto en plataformas digitales.

WITH count_like as (
  SELECT 
    EXTRACT (MONTH FROM event_date) as mes,
    COUNT(user_id) as user
  FROM user_actions
    WHERE event_date BETWEEN '2022-07-01 00:00:00' AND '2022-07-31 23:59:59' AND event_type='like'
    GROUP BY user_id, event_date
 )
SELECT 
  mes, 
  COUNT(user)
FROM 
  count_like
GROUP BY mes

