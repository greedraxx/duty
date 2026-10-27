-- 서류 보관 — supabase.sql 을 먼저 실행한 뒤, 이 파일을 SQL Editor 에서 Run
-- 파일은 Storage 가 아니라 DB(doc_chunks)에 조각으로 저장됩니다.
-- 일지·근무표와 같은 팀 코드(team_check)로 보호되고, 삭제는 불가능합니다(숨김만 가능).

create table if not exists public.docs (
  id         uuid primary key default gen_random_uuid(),
  title      text    not null check (char_length(title) between 1 and 200),
  category   text    not null default '기타' check (char_length(category) <= 40),
  note       text    not null default '' check (char_length(note) <= 2000),
  file_name  text    not null check (char_length(file_name) <= 255),
  mime       text    not null default 'application/octet-stream' check (char_length(mime) <= 120),
  size       bigint  not null check (size between 1 and 26214400),   -- 파일 1개 최대 25MB
  chunks     int     not null check (chunks between 1 and 80),
  hidden     boolean not null default false,                        -- true = 목록에서 숨김(삭제 대신)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists docs_created_idx on public.docs (created_at desc);

create table if not exists public.doc_chunks (
  doc_id uuid not null,
  seq    int  not null check (seq >= 0),
  data   text not null check (char_length(data) <= 1000000),       -- base64 조각
  primary key (doc_id, seq)
);

create or replace function private.touch_ts() returns trigger
language plpgsql security definer set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;

drop trigger if exists docs_touch on public.docs;
create trigger docs_touch before update on public.docs
  for each row execute function private.touch_ts();

revoke all on public.docs, public.doc_chunks from anon, authenticated;
grant select, insert, update on public.docs to anon;
grant select, insert on public.doc_chunks to anon;                -- 조각은 추가·읽기만 (수정·삭제 불가)

alter table public.docs       enable row level security;
alter table public.doc_chunks enable row level security;

drop policy if exists docs_select on public.docs;
drop policy if exists docs_insert on public.docs;
drop policy if exists docs_update on public.docs;
create policy docs_select on public.docs for select to anon using (public.team_check());
create policy docs_insert on public.docs for insert to anon with check (public.team_check());
create policy docs_update on public.docs for update to anon using (public.team_check()) with check (public.team_check());

drop policy if exists chunks_select on public.doc_chunks;
drop policy if exists chunks_insert on public.doc_chunks;
create policy chunks_select on public.doc_chunks for select to anon using (public.team_check());
create policy chunks_insert on public.doc_chunks for insert to anon with check (public.team_check());
