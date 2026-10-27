// Supabase 연결 정보 — Supabase 대시보드 › Project Settings › API 에서 복사
// 이 두 값은 웹페이지에 공개되는 값입니다. 실제 보호는 supabase.sql 의 팀 코드와 권한 설정이 합니다.
// (secret / service_role 키는 절대 여기에 넣지 마세요)
window.DUTY_CONFIG = {
  supabaseUrl: 'https://ryvjflvsnagukntdxzeb.supabase.co',
  supabaseKey: 'sb_publishable_zAAHcCR1ckftLVVcEIoaPg_lzh28mqz',

  // 날씨 자동 입력 위치 (기본: 서울시청). 끄려면 weather: false
  lat: 37.5665,
  lon: 126.978,
  weather: true,
};
