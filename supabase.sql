-- 시설팀 당직일지 — Supabase SQL Editor 에 통째로 붙여넣고 Run
-- 맨 아래 '팀 코드' 줄의 change-me-1234 를 원하는 코드(영문·숫자 4자 이상)로 바꾼 뒤 실행하세요.

-- 1) 테이블 ------------------------------------------------------------
create table if not exists public.logs (
  date       date primary key,               -- 일지 날짜
  data       jsonb not null,                 -- 그날 입력값 전체
  updated_at timestamptz not null default now()
);
create index if not exists logs_updated_at_idx on public.logs (updated_at);

create table if not exists public.config (
  key        text primary key,               -- 'base' = 시작 기준값
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

-- 비공개 영역: 팀 코드, 수정 이력 (웹에서 접근 불가)
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.team (code text primary key);

create table if not exists private.history (
  id          bigint generated always as identity primary key,
  tbl         text not null,
  key         text not null,
  data        jsonb,
  replaced_at timestamptz not null default now()
);

-- 2) 팀 코드 확인 함수 ---------------------------------------------------
-- 앱이 보내는 x-team-code 헤더가 private.team 의 코드와 같으면 true.
-- private.team 이 비어 있으면 코드 없이 누구나 사용 (권장하지 않음).
create or replace function public.team_check() returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from private.team)
      or exists (
        select 1 from private.team t
        where t.code = coalesce(
          (current_setting('request.headers', true)::json ->> 'x-team-code'), '')
      );
$$;
revoke execute on function public.team_check() from public;
grant execute on function public.team_check() to anon, authenticated;

-- 3) 저장 시각 갱신 + 덮어쓰기 전 값 보관 --------------------------------
create or replace function private.touch() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and old.data is distinct from new.data then
    insert into private.history (tbl, key, data)
    values (tg_table_name,
            coalesce(to_jsonb(old) ->> 'date', to_jsonb(old) ->> 'key'),
            old.data);
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists logs_touch on public.logs;
create trigger logs_touch before insert or update on public.logs
  for each row execute function private.touch();
drop trigger if exists config_touch on public.config;
create trigger config_touch before insert or update on public.config
  for each row execute function private.touch();

-- 4) 권한: 읽기·추가·수정만 허용, 삭제 불가 -------------------------------
revoke all on public.logs, public.config from anon, authenticated;
grant select, insert, update on public.logs, public.config to anon;

alter table public.logs   enable row level security;
alter table public.config enable row level security;

drop policy if exists logs_select on public.logs;
drop policy if exists logs_insert on public.logs;
drop policy if exists logs_update on public.logs;
create policy logs_select on public.logs for select to anon using (public.team_check());
create policy logs_insert on public.logs for insert to anon with check (public.team_check());
create policy logs_update on public.logs for update to anon using (public.team_check()) with check (public.team_check());

drop policy if exists config_select on public.config;
drop policy if exists config_insert on public.config;
drop policy if exists config_update on public.config;
create policy config_select on public.config for select to anon using (public.team_check());
create policy config_insert on public.config for insert to anon with check (public.team_check());
create policy config_update on public.config for update to anon using (public.team_check()) with check (public.team_check());

-- 5) 팀 코드 (여기만 바꾸세요) -------------------------------------------
-- 코드를 바꿀 때:  delete from private.team;  insert into private.team values ('새코드');
insert into private.team (code) values ('change-me-1234') on conflict do nothing;
