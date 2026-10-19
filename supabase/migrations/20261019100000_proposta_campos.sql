-- Campos da proposta no modelo do studio (pedido da Talise, 19/10/2026):
-- horário e local do evento, sinal solicitado e um serviço extra terceirizado (ex.: copeira).
alter table public.orcamentos
  add column horario          text           not null default '',
  add column local            text           not null default '',
  add column sinal            numeric(12, 2) not null default 0,
  add column sinal_ate        date,
  add column outros_descricao text           not null default '',
  add column outros_valor     numeric(12, 2) not null default 0;

comment on column public.orcamentos.horario          is 'Horário do evento, texto livre (ex.: 19h).';
comment on column public.orcamentos.local            is 'Local do evento (salão, residência, endereço).';
comment on column public.orcamentos.sinal            is 'Sinal solicitado para garantir a data (R$).';
comment on column public.orcamentos.sinal_ate        is 'Data limite para o pagamento do sinal.';
comment on column public.orcamentos.outros_descricao is 'Serviço extra terceirizado, descrição (ex.: Copeira).';
comment on column public.orcamentos.outros_valor     is 'Serviço extra terceirizado, valor (R$).';
