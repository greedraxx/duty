# 시설팀 당직일지

휴대폰으로 검침값·순찰 결과를 입력하면 전일검침·사용량·증감·월누계가 자동 계산되고, PC에서 A4 1장으로 출력·엑셀·PDF 저장하는 웹앱입니다.
화면은 GitHub Pages(무료), 데이터는 Supabase(무료)에 저장됩니다. 로그인 없이 **팀 코드**만 기기마다 한 번 입력합니다.

## 파일

| 파일 | 내용 |
|---|---|
| `index.html` | 앱 본체 |
| `config.js` | Supabase 주소·키, 날씨 위치 (**직접 수정**) |
| `supabase.sql` | 데이터베이스 설정 (Supabase에서 1회 실행) |
| `template.xlsx` | 엑셀 저장용 원본 양식 |
| `vendor/` | 엑셀·PDF 라이브러리 (외부 CDN 없이 동작) |

## 설치 (약 15분, 1회)

### 1. Supabase
1. https://supabase.com 가입 → **New project** (Region: Northeast Asia (Seoul) 권장, DB 비밀번호는 따로 보관)
2. 왼쪽 **SQL Editor** → `supabase.sql` 내용을 통째로 붙여넣기
3. 맨 아래 줄 `'change-me-1234'` 를 팀 코드로 바꾸기 — **영문·숫자 4자 이상**, 추측 어려운 값
4. **Run** → "Success" 확인
5. **Project Settings → API**(또는 API Keys)에서 두 값 복사
   - Project URL (`https://xxxx.supabase.co`)
   - publishable 키(`sb_publishable_...`) 또는 legacy **anon** 키
   - ⚠️ `secret` / `service_role` 키는 절대 쓰지 마세요

### 2. config.js 수정
```js
supabaseUrl: 'https://xxxx.supabase.co',
supabaseKey: 'sb_publishable_xxxx',
lat: 37.5665, lon: 126.978,   // 병원 위치 (날씨 자동 입력용)
```

### 3. GitHub Pages
1. GitHub에서 **New repository** → 이름 예: `facility-duty` → **Public** (무료 계정은 Public 저장소만 Pages 가능)
2. **Add file → Upload files** → 이 폴더의 파일 전부(`vendor` 폴더 포함) 끌어다 놓기 → Commit
3. **Settings → Pages** → Source: *Deploy from a branch*, Branch: `main` / `/ (root)` → Save
4. 1~2분 뒤 표시되는 주소(`https://아이디.github.io/facility-duty/`) 접속

### 4. 팀원 배포
- 주소와 팀 코드를 팀원에게 따로 전달 (같은 메시지에 같이 보내지 않기)
- 휴대폰: Safari/Chrome에서 열고 **홈 화면에 추가**
- 카카오톡 안 브라우저에서는 파일 저장이 막힐 수 있으니 외부 브라우저로 여세요

## 첫 사용
**기록 탭 → 시작 기준값**에 앱을 쓰기 시작하는 날의 **전날 종이 일지 값**(전일 검침·전일 사용량·월누계, 전월 말일 검침)을 한 번 입력합니다. 이후엔 앱 기록이 자동으로 이어집니다.

## 보안 — 무엇이 막히고 무엇이 안 막히나
- 저장소가 Public이라 코드와 Supabase 키는 누구나 볼 수 있습니다. 이 키만으로는 **읽기·쓰기 불가** — 팀 코드가 있어야 합니다(서버에서 검사).
- **삭제는 불가능**합니다(앱·API 모두). 덮어쓰기 전 값은 `private.history`에 자동 보관됩니다.
- 팀 코드를 아는 사람은 내용을 고칠 수 있습니다. 퇴사자 등이 있으면 코드를 바꾸세요:
  ```sql
  delete from private.team; insert into private.team values ('새코드');
  ```
  → 모든 기기에서 새 코드를 다시 입력하게 됩니다.
- 이 앱은 사용자별 로그인이 없으므로 "누가 고쳤는지"는 기록되지 않습니다.

## 데이터 보호
- 지하 등 신호가 없는 곳에서 입력하면 **기기에 보관** → 연결되면 자동 전송 (상단에 "오프라인 · 기기에 보관 중" 표시)
- 같은 날짜를 두 사람이 동시에 고치면 **나중에 저장한 쪽이 이깁니다**(이전 값은 history에 남음)
- **기록 탭 → 백업 · 설정 → 전체 백업 받기**: 월 1회 권장
- 잘못 덮어쓴 값 되살리기 (Supabase SQL Editor):
  ```sql
  select replaced_at, data from private.history where key = '2026-10-23' order by replaced_at desc;
  ```

## 무료 요금제 주의
- Supabase 무료 프로젝트는 **7일간 사용이 거의 없으면 일시정지**됩니다. 매일 입력하면 해당 없음. 정지되면 대시보드에서 **Resume project**로 복구(데이터 유지).
- 날씨는 Open-Meteo(무료, 키 없음)의 **일 단위 예보/관측**입니다. 하루 중 가장 나쁜 날씨 코드가 표시되므로(예: 잠깐 이슬비 → "비") 필요하면 직접 고치세요. 비어 있을 때만 채우고, 고친 값은 덮어쓰지 않습니다.

## 인쇄
일지 탭 → **출력** → 인쇄 창에서 용지 A4, 여백 **없음**, 배율 **100%**, *배경 그래픽* 켜기.
