-- 업무일지 — supabase.sql 을 먼저 실행한 뒤, 이 파일을 SQL Editor 에서 Run
-- 날짜별 메모 1건. 일지·근무표와 같은 팀 코드(team_check)로 보호, 삭제 불가, 덮어쓰기 전 내용은 private.history 에 보관.

create table if not exists public.journal (
  date       date primary key,
  body       text not null default '' check (char_length(body) <= 30000),
  updated_at timestamptz not null default now()
);
create index if not exists journal_updated_idx on public.journal (updated_at);

create or replace function private.touch_journal() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and old.body is distinct from new.body then
    insert into private.history (tbl, key, data)
    values ('journal', old.date::text, to_jsonb(old.body));
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists journal_touch on public.journal;
create trigger journal_touch before insert or update on public.journal
  for each row execute function private.touch_journal();

revoke all on public.journal from anon, authenticated;
grant select, insert, update on public.journal to anon;
alter table public.journal enable row level security;

drop policy if exists journal_select on public.journal;
drop policy if exists journal_insert on public.journal;
drop policy if exists journal_update on public.journal;
create policy journal_select on public.journal for select to anon using (public.team_check());
create policy journal_insert on public.journal for insert to anon with check (public.team_check());
create policy journal_update on public.journal for update to anon using (public.team_check()) with check (public.team_check());
