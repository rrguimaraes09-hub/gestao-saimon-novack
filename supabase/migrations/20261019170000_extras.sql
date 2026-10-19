-- Serviços extras terceirizados: de um campo único (descrição + valor) para uma lista,
-- porque um evento pode ter copeira, segurança, DJ etc. ao mesmo tempo.
alter table public.orcamentos
  add column extras jsonb not null default '[]'::jsonb;
comment on column public.orcamentos.extras is 'Serviços extras terceirizados: [{"descricao": "Copeira", "valor": 300}]';

-- Preserva o que já estava gravado no campo único
update public.orcamentos
set extras = jsonb_build_array(jsonb_build_object('descricao', outros_descricao, 'valor', outros_valor))
where outros_valor > 0 or outros_descricao <> '';

alter table public.orcamentos
  drop column outros_descricao,
  drop column outros_valor;
