insert into public.incidents (kind, source, status, lat, lng, description, confirmations, denials, starts_at, expires_at) values
  ('blockade', 'citizen', 'active', -16.5085, -68.1460, 'Bloqueo de vecinos en Av. Buenos Aires, no hay paso vehicular', 5, 0, now() - interval '2 hours', now() + interval '10 hours'),
  ('protest', 'citizen', 'active', -16.5005, -68.1335, 'Marcha sobre El Prado con dirección a Plaza San Francisco', 4, 0, now() - interval '1 hour', now() + interval '5 hours'),
  ('roadwork', 'official', 'active', -16.5330, -68.1010, 'Refacción de calzada en Av. Hernando Siles, un solo carril habilitado', 0, 0, now() - interval '2 days', now() + interval '5 days'),
  ('official_closure', 'official', 'active', -16.4900, -68.1180, 'Cierre programado por obras en Plaza Villarroel', 0, 0, now() - interval '1 day', now() + interval '2 days'),
  ('blockade', 'citizen', 'pending', -16.5210, -68.1240, 'Reportan bloqueo parcial cerca de la estación Libertador', 1, 0, now() - interval '20 minutes', now() + interval '11 hours');

insert into public.shared_experiences (zone, time_slot, content) values
  ('Sopocachi', '21:00-23:00', 'Después de las 21:30 ya casi no pasan minibuses por la Av. Ecuador, mejor bajar hasta la 6 de Agosto o pedir radiotaxi'),
  ('Obrajes', '05:00-07:00', 'A primera hora el PumaKatari de Chasquipampa pasa lleno, conviene esperar el segundo o usar la Línea Verde'),
  ('El Alto - Ceja', '20:00-23:00', 'De noche en La Ceja conviene tomar radiotaxi de parada y no taxis sueltos'),
  ('Centro', '12:00-14:00', 'Al mediodía el Prado se congestiona, el teleférico Celeste es más rápido que cualquier movilidad'),
  ('Miraflores', '18:00-20:00', 'Los micros a Miraflores se demoran por el tráfico del Busch, la Línea Blanca es opción directa');
