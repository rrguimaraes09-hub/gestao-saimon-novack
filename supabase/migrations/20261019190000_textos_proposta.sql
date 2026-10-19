-- Textos da proposta editáveis por evento (pedido da Talise): quando preenchidos, substituem
-- os textos padrão da tabela configuracoes só naquele orçamento.
-- Chaves: garcons, loucas, observacoes (texto livre; observações uma por linha).
alter table public.orcamentos
  add column textos jsonb not null default '{}'::jsonb;
comment on column public.orcamentos.textos is 'Textos da proposta só deste evento: {"garcons": "...", "loucas": "...", "observacoes": "uma por linha"}. Vazio usa o padrão de configuracoes.';
