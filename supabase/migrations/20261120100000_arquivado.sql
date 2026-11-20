-- Arquivo do funil: evento encerrado sai do quadro, mas continua no banco (orçamento, histórico do cliente).
alter table public.orcamentos
  add column arquivado boolean not null default false;

comment on column public.orcamentos.arquivado is 'Evento arquivado: some do funil (visível em "Ver arquivados"); orçamento e histórico continuam.';
