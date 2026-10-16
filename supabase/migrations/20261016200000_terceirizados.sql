-- Custos terceirizados do evento, separados do custo interno (equipe e logística):
-- garçons (quantidade × diária) e louças/utensílios (valor fechado).
alter table public.orcamentos
  add column garcons_qtd   integer        not null default 0,
  add column garcons_valor numeric(12, 2) not null default 0,
  add column loucas        numeric(12, 2) not null default 0;

comment on column public.orcamentos.equipe        is 'Custo interno: equipe própria, transporte e logística (R$).';
comment on column public.orcamentos.garcons_qtd   is 'Garçons terceirizados: quantidade.';
comment on column public.orcamentos.garcons_valor is 'Garçons terceirizados: diária por garçom (R$).';
comment on column public.orcamentos.loucas        is 'Louças e utensílios terceirizados (R$, valor fechado).';
