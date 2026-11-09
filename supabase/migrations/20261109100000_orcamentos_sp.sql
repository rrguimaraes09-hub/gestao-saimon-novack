-- Orçamentos de São Paulo: aba própria no app, com menu próprio e preço por soma simples.
-- Preço SP = gastronomia a custo (insumos das fichas do menu SP × pessoas) + garçons + custo de produção.
alter table public.orcamentos
  add column sp       boolean        not null default false,
  add column producao numeric(12, 2) not null default 0;

alter table public.fichas
  add column sp boolean not null default false;

comment on column public.orcamentos.sp       is 'Orçamento de São Paulo: aparece só na aba Orçamentos SP e usa o cálculo de SP.';
comment on column public.orcamentos.producao is 'SP: custo de produção, valor fechado (passagens, furgão, equipe, hospedagem e margem).';
comment on column public.fichas.sp           is 'Ficha do menu de São Paulo: aparece só na aba Orçamentos SP.';
