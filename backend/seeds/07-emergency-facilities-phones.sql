-- Upgrade: teléfonos de hospitales y puestos policiales (T5.1).
-- Ejecutar una vez en el SQL Editor de Supabase. Es idempotente
-- (siempre deja el mismo teléfono para cada facility por nombre).

update public.health_facilities set phone = '2-283-5959' where name = 'Hospital de Clínicas';
update public.health_facilities set phone = '2-240-8008' where name = 'Hospital Obrero N°1';
update public.health_facilities set phone = '2-244-1350' where name = 'Hospital del Niño Dr. Ovidio Aliaga';
update public.health_facilities set phone = '2-278-4141' where name = 'Hospital Arco Iris';
update public.health_facilities set phone = '2-284-2020' where name = 'Hospital Municipal La Portada';
update public.health_facilities set phone = '2-279-6161' where name = 'Hospital Municipal Los Pinos';
update public.health_facilities set phone = '2-278-4545' where name = 'Clínica del Sur';
update public.health_facilities set phone = '2-282-3030' where name = 'Hospital Agramont (El Alto)';
update public.health_facilities set phone = '2-222-0652' where name = 'FELCC La Paz';
update public.health_facilities set phone = '110' where name = 'EPI Sopocachi';
update public.health_facilities set phone = '110' where name = 'EPI San Pedro';
update public.health_facilities set phone = '110' where name = 'EPI Villa Fátima';
update public.health_facilities set phone = '110' where name = 'EPI Ceja El Alto';
