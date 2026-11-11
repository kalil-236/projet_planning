-- Phase 5 : heure réelle à laquelle une tâche est marquée faite.
-- À exécuter une fois dans l'éditeur SQL du projet Supabase, si le schéma a
-- été créé avant la phase 5. Sans risque si la colonne existe déjà.
alter table public.tasks add column if not exists completed_at timestamptz;
