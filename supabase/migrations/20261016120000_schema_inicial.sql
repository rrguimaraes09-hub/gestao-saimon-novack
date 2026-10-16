-- Gestão Saimon Novack: schema inicial
-- Projeto Supabase: gestao-saimon-novack (ref oeutngbawbdnkqokgcoy)
-- Aplicar com: npx supabase db push (depois de npx supabase login e npx supabase link)

-- ---------------------------------------------------------------
-- 1. Perfis e convites (controle de acesso)
-- ---------------------------------------------------------------

create table public.perfis (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text not null,
  nome          text not null default '',
  papel         text not null default 'equipe' check (papel in ('admin', 'equipe')),
  ativo         boolean not null default false,
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
comment on table public.perfis is 'Um perfil por usuário do auth. Só perfil ativo acessa os dados; admin gerencia perfis e convites.';

create table public.convites (
  id         uuid primary key default gen_random_uuid(),
  email      text not null,
  papel      text not null default 'equipe' check (papel in ('admin', 'equipe')),
  criado_por uuid references public.perfis (id) on delete set null,
  criado_em  timestamptz not null default now(),
  aceito_em  timestamptz
);
comment on table public.convites is 'Convite por e-mail. Quando a pessoa entra com esse e-mail, o perfil nasce ativo com o papel do convite.';
create unique index convites_email_pendente_unico on public.convites (lower(email)) where aceito_em is null;

-- Funções auxiliares para as políticas (security definer para não recair na RLS de perfis)
create or replace function public.perfil_ativo()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfis p
    where p.id = auth.uid() and p.ativo
  );
$$;

create or replace function public.sou_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfis p
    where p.id = auth.uid() and p.ativo and p.papel = 'admin'
  );
$$;

revoke execute on function public.perfil_ativo() from public, anon;
revoke execute on function public.sou_admin() from public, anon;
grant execute on function public.perfil_ativo() to authenticated;
grant execute on function public.sou_admin() to authenticated;

-- Carimbo de atualização
create or replace function public.marcar_atualizado_em()
returns trigger
language plpgsql
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

create trigger perfis_atualizado_em
  before update on public.perfis
  for each row execute function public.marcar_atualizado_em();

-- Novo usuário no auth: cria o perfil.
-- Regras: o primeiro usuário do projeto vira admin ativo (bootstrap);
-- quem tem convite pendente nasce ativo com o papel do convite;
-- os demais nascem inativos, à espera de liberação pelo admin.
create or replace function public.ao_criar_usuario()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_convite  public.convites%rowtype;
  v_primeiro boolean;
begin
  select * into v_convite
  from public.convites
  where lower(email) = lower(new.email) and aceito_em is null
  order by criado_em desc
  limit 1;

  select not exists (select 1 from public.perfis) into v_primeiro;

  insert into public.perfis (id, email, nome, papel, ativo)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nome', ''),
    case
      when v_primeiro then 'admin'
      when v_convite.id is not null then v_convite.papel
      else 'equipe'
    end,
    v_primeiro or v_convite.id is not null
  );

  if v_convite.id is not null then
    update public.convites set aceito_em = now() where id = v_convite.id;
  end if;

  return new;
end;
$$;

create trigger ao_criar_usuario
  after insert on auth.users
  for each row execute function public.ao_criar_usuario();

-- Convite para e-mail que já tem perfil (inativo): ativa o perfil na hora.
create or replace function public.ao_criar_convite()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_perfil public.perfis%rowtype;
begin
  new.email := lower(trim(new.email));

  select * into v_perfil from public.perfis where lower(email) = new.email limit 1;
  if v_perfil.id is not null then
    update public.perfis set ativo = true, papel = new.papel where id = v_perfil.id;
    new.aceito_em := now();
  end if;

  return new;
end;
$$;

create trigger ao_criar_convite
  before insert on public.convites
  for each row execute function public.ao_criar_convite();

-- Usuário comum só pode mudar o próprio nome (papel e ativo ficam com o admin).
create or replace function public.atualizar_meu_nome(novo_nome text)
returns void
language sql security definer
set search_path = public
as $$
  update public.perfis set nome = trim(novo_nome) where id = auth.uid();
$$;
revoke execute on function public.atualizar_meu_nome(text) from public, anon;
grant execute on function public.atualizar_meu_nome(text) to authenticated;

-- ---------------------------------------------------------------
-- 2. Dados operacionais (mesmos campos do protótipo, em snake_case)
-- ---------------------------------------------------------------

create table public.insumos (
  id            uuid primary key default gen_random_uuid(),
  nome          text not null default '',
  unidade       text not null default 'kg',
  custo         numeric(12, 4) not null default 0,
  exemplo       boolean not null default false,
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table public.fichas (
  id                  uuid primary key default gen_random_uuid(),
  nome                text not null default '',
  categoria           text not null default 'Principal',
  rendimento          numeric(10, 2) not null default 1,
  porcoes_por_pessoa  numeric(10, 2) not null default 1,
  itens               jsonb not null default '[]'::jsonb,  -- [{"insumo": uuid, "qtd": number}]
  preparo             text not null default '',
  exemplo             boolean not null default false,
  criado_em           timestamptz not null default now(),
  atualizado_em       timestamptz not null default now()
);
comment on column public.fichas.itens is 'Lista de insumos da receita: [{"insumo": "<uuid de insumos>", "qtd": <número na unidade do insumo>}]';

create table public.clientes (
  id              uuid primary key default gen_random_uuid(),
  nome            text not null default '',
  telefone        text not null default '',
  email           text not null default '',
  aniversario     date,
  origem          text not null default 'Instagram',
  prato_marcante  text not null default '',
  restricoes      text not null default '',  -- dado sensível (saúde): ver aviso de privacidade
  notas           text not null default '',
  consentimento   boolean not null default false,
  exemplo         boolean not null default false,
  criado_em       timestamptz not null default now(),
  atualizado_em   timestamptz not null default now()
);
comment on column public.clientes.restricoes is 'Restrições alimentares e alergias. Dado pessoal sensível (LGPD, art. 11): uso só para a execução do evento.';
comment on column public.clientes.consentimento is 'Autorizou contato comercial (aniversário, novidades, promoções).';

create table public.orcamentos (
  id            uuid primary key default gen_random_uuid(),
  cliente       uuid references public.clientes (id) on delete set null,
  servico       text not null default '',
  tipo_evento   text not null default '',
  data          date,
  cidade        text not null default '',
  convidados    integer not null default 0,
  origem        text not null default '',
  cardapio      uuid[] not null default '{}',  -- ids de fichas
  cmv           numeric(5, 2) not null default 30,
  equipe        numeric(12, 2) not null default 0,
  preco_final   numeric(12, 2) not null default 0,
  pago          numeric(12, 2) not null default 0,
  condicoes     text not null default '',
  etapa         text not null default 'pedido'
                check (etapa in ('pedido', 'enviado', 'aceito', 'sinal', 'realizado', 'avaliado', 'recusado')),
  nota          smallint check (nota between 1 and 5),
  comentario    text not null default '',
  depoimento    boolean not null default false,
  exemplo       boolean not null default false,
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index orcamentos_cliente_idx on public.orcamentos (cliente);
create index orcamentos_etapa_idx on public.orcamentos (etapa);

create trigger insumos_atualizado_em    before update on public.insumos    for each row execute function public.marcar_atualizado_em();
create trigger fichas_atualizado_em     before update on public.fichas     for each row execute function public.marcar_atualizado_em();
create trigger clientes_atualizado_em   before update on public.clientes   for each row execute function public.marcar_atualizado_em();
create trigger orcamentos_atualizado_em before update on public.orcamentos for each row execute function public.marcar_atualizado_em();

-- ---------------------------------------------------------------
-- 3. RLS
-- ---------------------------------------------------------------

alter table public.perfis     enable row level security;
alter table public.convites   enable row level security;
alter table public.insumos    enable row level security;
alter table public.fichas     enable row level security;
alter table public.clientes   enable row level security;
alter table public.orcamentos enable row level security;

-- Anônimo não vê nada (sem política para anon e sem privilégio de tabela)
revoke all on all tables in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;

-- perfis: cada um lê o próprio; admin lê, altera e remove os demais
create policy perfis_leitura on public.perfis
  for select to authenticated
  using (id = auth.uid() or public.sou_admin());

create policy perfis_admin_altera on public.perfis
  for update to authenticated
  using (public.sou_admin())
  with check (public.sou_admin());

create policy perfis_admin_remove on public.perfis
  for delete to authenticated
  using (public.sou_admin() and id <> auth.uid());

-- convites: só admin
create policy convites_admin on public.convites
  for all to authenticated
  using (public.sou_admin())
  with check (public.sou_admin());

-- dados operacionais: qualquer perfil ativo lê e grava
create policy insumos_equipe on public.insumos
  for all to authenticated
  using (public.perfil_ativo()) with check (public.perfil_ativo());

create policy fichas_equipe on public.fichas
  for all to authenticated
  using (public.perfil_ativo()) with check (public.perfil_ativo());

create policy clientes_equipe on public.clientes
  for all to authenticated
  using (public.perfil_ativo()) with check (public.perfil_ativo());

create policy orcamentos_equipe on public.orcamentos
  for all to authenticated
  using (public.perfil_ativo()) with check (public.perfil_ativo());

-- ---------------------------------------------------------------
-- 4. Realtime (a tela atualiza quando alguém da equipe grava)
-- ---------------------------------------------------------------

alter publication supabase_realtime add table
  public.insumos, public.fichas, public.clientes, public.orcamentos, public.perfis, public.convites;
