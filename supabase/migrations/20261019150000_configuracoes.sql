-- Configurações do studio editáveis pelo app (textos da proposta, dados de pagamento etc.).
-- Ficam no banco, atrás do login: nada disso vai para o repositório público.
create table public.configuracoes (
  chave          text primary key,
  valor          jsonb not null default '{}'::jsonb,
  atualizado_em  timestamptz not null default now(),
  atualizado_por uuid references public.perfis (id) on delete set null
);
comment on table public.configuracoes is 'Configurações do studio por chave (ex.: proposta). Perfil ativo lê; só admin grava.';

create trigger configuracoes_atualizado_em
  before update on public.configuracoes
  for each row execute function public.marcar_atualizado_em();

alter table public.configuracoes enable row level security;
revoke all on public.configuracoes from anon;

create policy configuracoes_leitura on public.configuracoes
  for select to authenticated
  using (public.perfil_ativo());

create policy configuracoes_admin_insere on public.configuracoes
  for insert to authenticated
  with check (public.sou_admin());

create policy configuracoes_admin_altera on public.configuracoes
  for update to authenticated
  using (public.sou_admin())
  with check (public.sou_admin());

alter publication supabase_realtime add table public.configuracoes;
