-- Schéma Supabase de l'assistant de planification (section 7.3).
-- À exécuter une seule fois dans l'éditeur SQL du projet Supabase.

create table public.categories (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  label text not null,
  icon text not null,
  color text not null,
  primary key (user_id, id)
);

create table public.tasks (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  date date not null,
  start_time time not null,
  end_time time not null check (end_time > start_time),
  category_id text not null default 'autre',
  notes text,
  reminder_before_min int check (reminder_before_min >= 0),
  status text not null default 'todo' check (status in ('todo','done','cancelled','missed')),
  shifted boolean not null default false,
  original_start_time time,
  source text not null default 'manual' check (source in ('import','manual')),
  import_batch_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  -- Ajout de la phase 5 : instant où la tâche a été marquée faite.
  completed_at timestamptz,
  -- Ajout à la section 7.3 : instant de réception par le serveur.
  synced_at timestamptz not null default clock_timestamp()
);
create index tasks_user_date_idx on public.tasks (user_id, date);
create index tasks_user_synced_idx on public.tasks (user_id, synced_at);

create table public.settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  day_start time not null default '07:00',
  day_end time not null default '22:00',
  timezone text not null default 'Africa/Porto-Novo',
  default_reminder_min int not null default 10,
  morning_summary_enabled boolean not null default true,
  morning_summary_time time not null default '07:00',
  theme_mode text not null default 'system',
  updated_at timestamptz not null default now(),
  synced_at timestamptz not null default clock_timestamp()
);

alter table public.categories enable row level security;
alter table public.tasks      enable row level security;
alter table public.settings   enable row level security;

create policy "own rows" on public.categories for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.tasks      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.settings   for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Le plus récent gagne (section 11.3) : une écriture plus ancienne que la ligne
-- en base est ignorée. `synced_at` permet à chaque appareil de récupérer aussi
-- les modifications faites hors ligne, dont `updated_at` est ancien.
create function public.apply_last_write_wins()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return null;
  end if;
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

create trigger tasks_last_write_wins
  before insert or update on public.tasks
  for each row execute function public.apply_last_write_wins();

create trigger settings_last_write_wins
  before insert or update on public.settings
  for each row execute function public.apply_last_write_wins();

alter publication supabase_realtime add table public.tasks, public.settings;
