#! /bin/bash

setenforce 0
grubby --update-kernel ALL --args selinux=0
dnf install -y wget httpd php php-gd php-mysqlnd php-curl php-opcache
wget https://ko.wordpress.org/wordpress-7.0-ko_KR.tar.gz
tar zxvf wordpress-7.0-ko_KR.tar.gz
cp -ar ./wordpress/* /var/www/html/
cp /var/www/html/wp-config{-sample,}.php
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/httpd/conf/httpd.conf
sed -i "s/database_name_here/wordpress/g; s/username_here/team63/g; s/password_here/${db_pswd}/g; s/localhost/192.168.10.11/g" /var/www/html/wp-config.php
cat << 'EOF' > /var/www/html/index.php
<?php
$host     = '192.168.10.11';
$db       = 'wordpress';
$user     = 'team63';
EOF

echo "\$password = '${db_pswd}';" >> /var/www/html/index.php

cat << 'EOF' >> /var/www/html/index.php
$charset  = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $password, $options);

    // 2. [핵심] 테이블 자동 생성 로직 (일정 정보를 저장할 테이블)
    $createTableSql = "CREATE TABLE IF NOT EXISTS schedules (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        ev_date DATE NOT NULL,
        ev_time TIME NULL,
        category VARCHAR(50) NULL,
        memo TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;";
    $pdo->exec($createTableSql);

    // 3. JavaScript가 비동기(POST)로 일정을 보냈을 때 처리하는 백엔드 API 라우터
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['api']) && $_GET['api'] === 'add_event') {
        // Raw JSON 데이터 파싱
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!empty($input['title'])) {
            $ev_date = !empty($input['date']) ? $input['date'] : date('Y-m-d');
            $ev_time = !empty($input['time']) ? $input['time'] : null;
            $category = !empty($input['category']) ? $input['category'] : '기타';
            $memo = !empty($input['memo']) ? $input['memo'] : null;

            $stmt = $pdo->prepare("INSERT INTO schedules (title, ev_date, ev_time, category, memo) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([
                $input['title'],
                $ev_date,
                $ev_time,
                $category,
                $memo
            ]);
            
            // 성공 응답 반환 후 PHP 종료
            header('Content-Type: application/json');
            echo json_encode(['status' => 'success']);
            exit;
        }
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['api']) && $_GET['api'] === 'delete_event') {
        header('Content-Type: application/json');
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 삭제할 일정의 제목(title)이나 ID 값을 기준으로 매칭합니다.
        if (!empty($input['title'])) {
            // 안전하게 준비된 문장(Prepared Statement)으로 DELETE 쿼리 실행
            $stmt = $pdo->prepare("DELETE FROM schedules WHERE title = ? AND ev_date = ?");
            $stmt->execute([
                $input['title'],
                $input['date']
            ]);
            
            echo json_encode(['status' => 'success']);
            exit;
        }
    }

    } catch (\PDOException $e) {
    // 💡 오류 추적이 쉽도록 화면에 DB 에러를 명시합니다.
    $dbError = $e->getMessage();
}
?>
<?php if (isset($dbError)): ?>
    <div style="color:red; background:white; padding:20px;">DB 연결 실패: <?php echo $dbError; ?></div>
<?php endif; ?>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dayflow ? 일정 & 할 일</title>
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0e0f11;--surface:#16181c;--surface2:#1e2025;--surface3:#262930;
  --border:#2e3038;--border2:#3a3d47;
  --text:#f0f1f3;--text2:#9ea3b0;--text3:#5c6070;
  --accent:#7c6aff;--accent2:#a394ff;--accent-glow:rgba(124,106,255,.18);
  --green:#3ecf8e;--red:#f87171;--amber:#fbbf24;--blue:#60a5fa;
  --radius:14px;--radius-sm:8px;
  --font-head:'Instrument Serif',serif;
  --font-body:'DM Sans',sans-serif;
  --sidebar:260px;
}
html{font-size:15px}
body{font-family:var(--font-body);background:var(--bg);color:var(--text);min-height:100vh;overflow-x:hidden}

/* ── 로그인 화면 ───────────────────────────────────────── */
#login-screen{
  position:fixed;inset:0;background:var(--bg);z-index:100;
  display:flex;align-items:center;justify-content:center;
  background-image:radial-gradient(ellipse 60% 50% at 50% -10%,rgba(124,106,255,.25),transparent);
}
.login-box{
  width:360px;padding:48px 40px;
  background:var(--surface);border:1px solid var(--border);border-radius:24px;
  display:flex;flex-direction:column;gap:24px;
  animation:fadeUp .5s ease both;
}
.login-logo{font-family:var(--font-head);font-size:32px;color:var(--text);letter-spacing:-.5px}
.login-logo span{color:var(--accent)}
.login-tagline{font-size:13px;color:var(--text3);margin-top:-16px}
.field{display:flex;flex-direction:column;gap:6px}
.field label{font-size:12px;font-weight:500;color:var(--text2);letter-spacing:.04em;text-transform:uppercase}
.field input{
  background:var(--surface2);border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:11px 14px;font-size:14px;color:var(--text);font-family:var(--font-body);
  outline:none;transition:.2s;
}
.field input:focus{border-color:var(--accent);background:var(--surface3)}
.btn-primary{
  background:var(--accent);color:#fff;border:none;border-radius:var(--radius-sm);
  padding:12px;font-size:14px;font-weight:600;font-family:var(--font-body);
  cursor:pointer;transition:opacity .2s,transform .1s;
}
.btn-primary:hover{opacity:.9}
.btn-primary:active{transform:scale(.98)}
.login-hint{font-size:12px;color:var(--text3);text-align:center}
.login-hint b{color:var(--text2);font-weight:500}
.login-error{font-size:12px;color:var(--red);text-align:center;display:none}

/* ── 앱 레이아웃 ─────────────────────────────────────── */
#app{display:none;height:100vh;overflow:hidden}
.layout{display:grid;grid-template-columns:var(--sidebar) 1fr;height:100vh}

/* ── 사이드바 ─────────────────────────────────────────── */
.sidebar{
  background:var(--surface);border-right:1px solid var(--border);
  display:flex;flex-direction:column;padding:24px 16px;gap:4px;overflow-y:auto;
}
.sidebar-logo{font-family:var(--font-head);font-size:22px;padding:8px 12px 20px;color:var(--text)}
.sidebar-logo span{color:var(--accent)}
.nav-section{font-size:10px;font-weight:600;color:var(--text3);letter-spacing:.1em;text-transform:uppercase;padding:16px 12px 6px}
.nav-item{
  display:flex;align-items:center;gap:10px;padding:9px 12px;border-radius:var(--radius-sm);
  font-size:13.5px;color:var(--text2);cursor:pointer;transition:.15s;
  text-decoration:none;
}
.nav-item:hover{background:var(--surface2);color:var(--text)}
.nav-item.active{background:var(--accent-glow);color:var(--accent2)}
.nav-item svg{width:16px;height:16px;flex-shrink:0}
.sidebar-footer{margin-top:auto;padding-top:16px;border-top:1px solid var(--border)}
.user-row{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:var(--radius-sm)}
.avatar{width:32px;height:32px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;color:#fff;flex-shrink:0}
.user-info{min-width:0}
.user-name{font-size:13px;font-weight:500;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.user-email{font-size:11px;color:var(--text3);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.logout-btn{margin-left:auto;background:none;border:none;color:var(--text3);cursor:pointer;padding:4px;border-radius:4px}
.logout-btn:hover{color:var(--red)}

/* ── 메인 영역 ─────────────────────────────────────────── */
.main{overflow-y:auto;background:var(--bg)}
.page{display:none;padding:32px 36px;animation:fadeIn .3s ease both}
.page.active{display:block}
.page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:28px}
.page-title{font-family:var(--font-head);font-size:30px;color:var(--text);letter-spacing:-.3px}
.page-sub{font-size:13px;color:var(--text3);margin-top:2px}

/* ── 버튼 ─────────────────────────────────────────────── */
.btn{
  display:inline-flex;align-items:center;gap:6px;padding:9px 16px;
  border-radius:var(--radius-sm);font-size:13px;font-weight:500;
  font-family:var(--font-body);cursor:pointer;border:none;transition:.15s;
}
.btn-accent{background:var(--accent);color:#fff}
.btn-accent:hover{background:var(--accent2)}
.btn-ghost{background:var(--surface2);color:var(--text2);border:1px solid var(--border)}
.btn-ghost:hover{background:var(--surface3);color:var(--text)}
.btn-danger{background:rgba(248,113,113,.12);color:var(--red);border:1px solid rgba(248,113,113,.2)}
.btn-danger:hover{background:rgba(248,113,113,.2)}

/* ── 캘린더 ──────────────────────────────────────────── */
.calendar-wrap{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.cal-header{display:flex;align-items:center;justify-content:space-between;padding:20px 24px;border-bottom:1px solid var(--border)}
.cal-title{font-family:var(--font-head);font-size:22px;color:var(--text)}
.cal-nav{display:flex;gap:4px}
.cal-nav button{background:var(--surface2);border:1px solid var(--border);color:var(--text2);width:32px;height:32px;border-radius:var(--radius-sm);cursor:pointer;font-size:16px;display:flex;align-items:center;justify-content:center;transition:.15s}
.cal-nav button:hover{background:var(--surface3);color:var(--text)}
.cal-grid{display:grid;grid-template-columns:repeat(7,1fr)}
.cal-day-header{padding:10px 0;text-align:center;font-size:11px;font-weight:600;color:var(--text3);letter-spacing:.06em;text-transform:uppercase;border-bottom:1px solid var(--border)}
.cal-day{
  min-height:88px;padding:8px;border-right:1px solid var(--border);border-bottom:1px solid var(--border);
  cursor:pointer;transition:.15s;position:relative;
}
.cal-day:hover{background:var(--surface2)}
.cal-day.selected{background:var(--accent-glow)}
.cal-day.today .day-num{background:var(--accent);color:#fff;border-radius:50%;width:24px;height:24px;display:flex;align-items:center;justify-content:center}
.cal-day.other-month .day-num{color:var(--text3)}
.cal-day:nth-child(7n){border-right:none}
.day-num{font-size:13px;font-weight:500;color:var(--text2);margin-bottom:4px;width:24px;height:24px;display:flex;align-items:center;justify-content:center}
.event-dot{font-size:11px;padding:2px 6px;border-radius:4px;margin-bottom:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;cursor:pointer}
.event-dot.color-0{background:rgba(124,106,255,.25);color:#a394ff}
.event-dot.color-1{background:rgba(62,207,142,.2);color:#3ecf8e}
.event-dot.color-2{background:rgba(251,191,36,.2);color:#fbbf24}
.event-dot.color-3{background:rgba(96,165,250,.2);color:#60a5fa}
.event-dot.color-4{background:rgba(248,113,113,.2);color:#f87171}
.more-dots{font-size:10px;color:var(--text3);padding-left:4px}

/* ── 오늘 뷰 사이드 패널 ─────────────────────────────── */
.cal-layout{display:grid;grid-template-columns:1fr 300px;gap:20px;align-items:start}
.day-panel{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:20px}
.day-panel-title{font-family:var(--font-head);font-size:18px;margin-bottom:16px;color:var(--text)}
.day-event-item{
  display:flex;align-items:flex-start;gap:10px;padding:10px 12px;
  border-radius:var(--radius-sm);margin-bottom:6px;background:var(--surface2);
  border-left:3px solid var(--accent);cursor:pointer;transition:.15s;
}
.day-event-item:hover{background:var(--surface3)}
.dei-time{font-size:11px;color:var(--text3);white-space:nowrap;margin-top:1px}
.dei-info{flex:1;min-width:0}
.dei-title{font-size:13px;font-weight:500;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.dei-tags{display:flex;gap:4px;margin-top:3px;flex-wrap:wrap}
.tag-pill{font-size:10px;padding:1px 6px;border-radius:20px}
.repeat-tag{background:rgba(96,165,250,.15);color:#60a5fa}
.reminder-tag{background:rgba(62,207,142,.15);color:#3ecf8e}
.empty-state{text-align:center;padding:32px 0;color:var(--text3);font-size:13px}
.empty-state svg{width:32px;height:32px;margin:0 auto 10px;display:block;opacity:.3}

/* ── 모달 ─────────────────────────────────────────────── */
.overlay{position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:50;display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px)}
.overlay.open{display:flex}
.modal{
  background:var(--surface);border:1px solid var(--border);border-radius:20px;
  width:480px;max-height:90vh;overflow-y:auto;
  animation:fadeUp .25s ease both;
}
.modal-header{padding:24px 24px 16px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid var(--border)}
.modal-title{font-family:var(--font-head);font-size:20px;color:var(--text)}
.modal-close{background:none;border:none;color:var(--text3);font-size:22px;cursor:pointer;line-height:1;padding:2px 6px;border-radius:4px}
.modal-close:hover{color:var(--text);background:var(--surface2)}
.modal-body{padding:20px 24px;display:flex;flex-direction:column;gap:16px}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.form-field{display:flex;flex-direction:column;gap:6px}
.form-field.full{grid-column:1/-1}
.form-label{font-size:12px;font-weight:500;color:var(--text2);letter-spacing:.04em;text-transform:uppercase}
.form-input{
  background:var(--surface2);border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:10px 12px;font-size:13.5px;color:var(--text);font-family:var(--font-body);
  outline:none;transition:.2s;width:100%;
}
.form-input:focus{border-color:var(--accent)}
.form-input option{background:var(--surface2)}
select.form-input{cursor:pointer}
.color-picker{display:flex;gap:8px}
.color-swatch{width:28px;height:28px;border-radius:50%;cursor:pointer;border:2px solid transparent;transition:.15s}
.color-swatch.active{border-color:#fff;transform:scale(1.15)}
.checkbox-row{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--text2)}
.checkbox-row input[type=checkbox]{accent-color:var(--accent);width:15px;height:15px;cursor:pointer}
.modal-footer{padding:16px 24px;border-top:1px solid var(--border);display:flex;gap:8px;justify-content:flex-end}

/* ── 할 일 ──────────────────────────────────────────── */
.todo-header-row{display:flex;align-items:center;gap:12px;margin-bottom:20px}
.today-badge{
  background:var(--accent-glow);color:var(--accent2);
  font-size:12px;font-weight:500;padding:4px 12px;border-radius:20px;
}
.progress-bar-wrap{background:var(--surface2);border-radius:999px;height:6px;flex:1;overflow:hidden}
.progress-bar{height:100%;background:var(--accent);border-radius:999px;transition:width .4s ease}
.progress-label{font-size:12px;color:var(--text3);white-space:nowrap}
.todo-section{margin-bottom:24px}
.todo-section-title{font-size:11px;font-weight:600;color:var(--text3);letter-spacing:.1em;text-transform:uppercase;margin-bottom:10px;padding-bottom:6px;border-bottom:1px solid var(--border)}
.todo-item{
  display:flex;align-items:center;gap:12px;padding:12px 14px;
  background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);
  margin-bottom:6px;transition:.2s;cursor:default;
}
.todo-item:hover{border-color:var(--border2)}
.todo-item.done{opacity:.5}
.todo-item.done .todo-title{text-decoration:line-through;color:var(--text3)}
.todo-check{
  width:20px;height:20px;border-radius:6px;border:2px solid var(--border2);
  cursor:pointer;flex-shrink:0;display:flex;align-items:center;justify-content:center;transition:.15s;
}
.todo-check:hover{border-color:var(--accent)}
.todo-check.checked{background:var(--accent);border-color:var(--accent)}
.todo-check.checked::after{content:'?';color:#fff;font-size:11px;font-weight:700}
.todo-title{flex:1;font-size:13.5px;color:var(--text)}
.todo-time{font-size:11px;color:var(--text3);white-space:nowrap}
.todo-color{width:8px;height:8px;border-radius:50%;flex-shrink:0}
.add-todo-row{display:flex;gap:8px;margin-top:8px}
.add-todo-input{flex:1;background:var(--surface2);border:1px solid var(--border);border-radius:var(--radius-sm);padding:10px 12px;font-size:13px;color:var(--text);font-family:var(--font-body);outline:none}
.add-todo-input:focus{border-color:var(--accent)}
.add-todo-input::placeholder{color:var(--text3)}

/* ── 대시보드 ────────────────────────────────────────── */
.dash-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:24px}
.stat-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:20px}
.stat-label{font-size:11px;font-weight:600;color:var(--text3);letter-spacing:.08em;text-transform:uppercase;margin-bottom:8px}
.stat-val{font-family:var(--font-head);font-size:36px;color:var(--text);line-height:1}
.stat-sub{font-size:12px;color:var(--text3);margin-top:4px}
.upcoming-list{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.ul-header{padding:16px 20px;border-bottom:1px solid var(--border);font-size:13px;font-weight:600;color:var(--text)}
.ul-item{display:flex;align-items:center;gap:14px;padding:12px 20px;border-bottom:1px solid var(--border);transition:.15s;cursor:pointer}
.ul-item:last-child{border-bottom:none}
.ul-item:hover{background:var(--surface2)}
.ul-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0}
.ul-info{flex:1;min-width:0}
.ul-title{font-size:13.5px;font-weight:500;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ul-date{font-size:11px;color:var(--text3)}
.ul-badge{font-size:10px;padding:2px 7px;border-radius:20px;background:var(--accent-glow);color:var(--accent2)}

/* ── 알림 토스트 ─────────────────────────────────────── */
#toast-wrap{position:fixed;top:20px;right:20px;z-index:200;display:flex;flex-direction:column;gap:8px}
.toast{
  background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);
  padding:12px 16px;font-size:13px;color:var(--text);
  display:flex;align-items:center;gap:10px;min-width:260px;max-width:340px;
  animation:slideIn .3s ease both;box-shadow:0 4px 24px rgba(0,0,0,.4);
}
.toast.reminder{border-left:3px solid var(--green)}
.toast.info{border-left:3px solid var(--accent)}
.toast-icon{font-size:16px;flex-shrink:0}
.toast-body{flex:1}
.toast-title{font-weight:600;font-size:12px;color:var(--text2);text-transform:uppercase;letter-spacing:.06em;margin-bottom:2px}
.toast-msg{color:var(--text)}
.toast-close{background:none;border:none;color:var(--text3);cursor:pointer;font-size:16px;padding:0}
.toast-close:hover{color:var(--text)}

/* ── 애니메이션 ─────────────────────────────────────── */
@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
@keyframes slideIn{from{opacity:0;transform:translateX(20px)}to{opacity:1;transform:none}}
</style>
</head>
<body>

<!-- ── 로그인 ────────────────────────────────────────── -->
<div id="login-screen">
  <div class="login-box">
    <div>
      <div class="login-logo">Day<span>flow</span></div>
      <div class="login-tagline">일정과 할 일을 한 곳에서</div>
    </div>
    <div class="field">
      <label>이메일</label>
      <input type="email" id="login-email" placeholder="아이디 입력">
    </div>
    <div class="field">
      <label>비밀번호</label>
      <input type="password" id="login-pw" placeholder="비밀번호 입력">
    </div>
    <div class="login-error" id="login-error">이메일 또는 비밀번호가 올바르지 않습니다.</div>
    <button class="btn-primary" id="login-btn">로그인</button>
  </div>
</div>

<!-- ── 앱 ────────────────────────────────────────────── -->
<div id="app">
<div class="layout">

  <!-- 사이드바 -->
  <aside class="sidebar">
    <div class="sidebar-logo">Day<span>flow</span></div>
    <div class="nav-section">메뉴</div>
    <div class="nav-item active" data-page="dashboard">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
      대시보드
    </div>
    <div class="nav-item" data-page="calendar">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
      캘린더
    </div>
    <div class="nav-item" data-page="todos">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
      오늘 할 일
    </div>
    <div class="sidebar-footer">
      <div class="user-row">
        <div class="avatar" id="user-avatar">D</div>
        <div class="user-info">
          <div class="user-name" id="user-name">Demo User</div>
          <div class="user-email" id="user-email">demo@dayflow.app</div>
        </div>
        <button class="logout-btn" id="logout-btn" title="로그아웃">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        </button>
      </div>
    </div>
  </aside>

  <!-- 메인 -->
  <main class="main">

    <!-- 대시보드 -->
    <section class="page active" id="page-dashboard">
      <div class="page-header">
        <div>
          <div class="page-title">안녕하세요 ?</div>
          <div class="page-sub" id="dash-date-label"></div>
        </div>
        <button class="btn btn-accent" id="btn-new-event">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          새 일정
        </button>
      </div>
      <div class="dash-grid">
        <div class="stat-card">
          <div class="stat-label">오늘 일정</div>
          <div class="stat-val" id="stat-today">0</div>
          <div class="stat-sub">개의 일정이 있어요</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">할 일 완료</div>
          <div class="stat-val" id="stat-done">0</div>
          <div class="stat-sub" id="stat-done-sub">오늘 총 0개</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">이번 주 일정</div>
          <div class="stat-val" id="stat-week">0</div>
          <div class="stat-sub">개 예정</div>
        </div>
      </div>
      <div class="upcoming-list">
        <div class="ul-header">다가오는 일정</div>
        <div id="upcoming-list-body"></div>
      </div>
    </section>

    <!-- 캘린더 -->
    <section class="page" id="page-calendar">
      <div class="page-header">
        <div>
          <div class="page-title">캘린더</div>
          <div class="page-sub">일정을 클릭하면 상세 정보를 확인할 수 있어요</div>
        </div>
        <button class="btn btn-accent" id="btn-new-event2">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          새 일정
        </button>
      </div>
      <div class="cal-layout">
        <div class="calendar-wrap">
          <div class="cal-header">
            <div class="cal-title" id="cal-month-label"></div>
            <div class="cal-nav">
              <button id="cal-prev">?</button>
              <button id="cal-today-btn" style="width:auto;padding:0 10px;font-size:12px">오늘</button>
              <button id="cal-next">?</button>
            </div>
          </div>
          <div class="cal-grid" id="cal-day-headers"></div>
          <div class="cal-grid" id="cal-body"></div>
        </div>
        <div class="day-panel">
          <div class="day-panel-title" id="day-panel-title">날짜를 선택하세요</div>
          <div id="day-panel-events"></div>
        </div>
      </div>
    </section>

    <!-- 할 일 -->
    <section class="page" id="page-todos">
      <div class="page-header">
        <div>
          <div class="page-title">오늘 할 일</div>
          <div class="page-sub" id="todo-date-label"></div>
        </div>
      </div>
      <div class="todo-header-row">
        <div class="today-badge" id="todo-badge">0 / 0 완료</div>
        <div class="progress-bar-wrap"><div class="progress-bar" id="todo-progress" style="width:0%"></div></div>
        <div class="progress-label" id="todo-pct">0%</div>
      </div>
      <div id="todo-body"></div>
      <div class="add-todo-row">
        <input class="add-todo-input" id="add-todo-input" placeholder="+ 빠른 할 일 추가 (Enter로 저장)">
        <button class="btn btn-accent" id="add-todo-btn">추가</button>
      </div>
    </section>

  </main>
</div>
</div>

<!-- ── 일정 추가/수정 모달 ─────────────────────────────── -->
<div class="overlay" id="event-modal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title" id="modal-title-text">새 일정 추가</div>
      <button class="modal-close" id="modal-close">?</button>
    </div>
    <div class="modal-body">
      <div class="form-field full">
        <div class="form-label">제목</div>
        <input class="form-input" id="ev-title" placeholder="일정 제목">
      </div>
      <div class="form-row">
        <div class="form-field">
          <div class="form-label">날짜</div>
          <input type="date" class="form-input" id="ev-date">
        </div>
        <div class="form-field">
          <div class="form-label">시간</div>
          <input type="time" class="form-input" id="ev-time">
        </div>
      </div>
      <div class="form-row">
        <div class="form-field">
          <div class="form-label">종료 시간</div>
          <input type="time" class="form-input" id="ev-end-time">
        </div>
        <div class="form-field">
          <div class="form-label">카테고리</div>
          <select class="form-input" id="ev-category">
            <option value="업무">업무</option>
            <option value="개인">개인</option>
            <option value="건강">건강</option>
            <option value="학습">학습</option>
            <option value="기타">기타</option>
          </select>
        </div>
      </div>
      <div class="form-field full">
        <div class="form-label">색상</div>
        <div class="color-picker">
          <div class="color-swatch active" data-color="0" style="background:#7c6aff"></div>
          <div class="color-swatch" data-color="1" style="background:#3ecf8e"></div>
          <div class="color-swatch" data-color="2" style="background:#fbbf24"></div>
          <div class="color-swatch" data-color="3" style="background:#60a5fa"></div>
          <div class="color-swatch" data-color="4" style="background:#f87171"></div>
        </div>
      </div>
      <div class="form-field full">
        <div class="form-label">반복</div>
        <select class="form-input" id="ev-repeat">
          <option value="none">반복 없음</option>
          <option value="daily">매일</option>
          <option value="weekly">매주</option>
          <option value="monthly">매월</option>
          <option value="weekday">평일만 (월?금)</option>
        </select>
      </div>
      <div class="form-field full" id="repeat-end-wrap" style="display:none">
        <div class="form-label">반복 종료일</div>
        <input type="date" class="form-input" id="ev-repeat-end">
      </div>
      <div class="checkbox-row">
        <input type="checkbox" id="ev-reminder" checked>
        <label for="ev-reminder">알림 설정 (시작 10분 전)</label>
      </div>
      <div class="form-field full">
        <div class="form-label">메모</div>
        <textarea class="form-input" id="ev-memo" rows="2" placeholder="메모 (선택)"></textarea>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-danger" id="ev-delete-btn" style="display:none">삭제</button>
      <button class="btn btn-ghost" id="modal-cancel">취소</button>
      <button class="btn btn-accent" id="ev-save-btn">저장</button>
    </div>
  </div>
</div>

<!-- ── 알림 토스트 ───────────────────────────────────── -->
<div id="toast-wrap"></div>

<script>
// ── 상수 & 헬퍼 ────────────────────────────────────────────
const DAYS_KO = ['일','월','화','수','목','금','토'];
const MONTHS_KO = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];
const COLORS = ['#7c6aff','#3ecf8e','#fbbf24','#60a5fa','#f87171'];

const fmtDate = d => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const fmtDateKo = d => `${d.getFullYear()}년 ${d.getMonth()+1}월 ${d.getDate()}일 (${DAYS_KO[d.getDay()]})`;
const today = () => fmtDate(new Date());
const $  = id => document.getElementById(id);
const el = (tag,cls,txt) => { const e=document.createElement(tag); if(cls)e.className=cls; if(txt)e.textContent=txt; return e; };

// ── 스토리지 ────────────────────────────────────────────────
let state = {
  user: null,
  events: [],
  todos: [],
  nextId: 1,
};

function save() { localStorage.setItem('dayflow_state', JSON.stringify(state)); }
function load() {
  const raw = localStorage.getItem('dayflow_state');
  if (raw) { try { state = { ...state, ...JSON.parse(raw) }; } catch {} }
}
load();

// ── 로그인 ──────────────────────────────────────────────────
$('login-btn').onclick = doLogin;
$('login-pw').onkeydown = e => { if(e.key==='Enter') doLogin(); };

function doLogin() {
  const email = $('login-email').value.trim();
  const pw    = $('login-pw').value;
  if (email === 'team63@dayflow.app' && pw === 'It12345@') {
    state.user = { email, name: 'Demo User' };
    save();
    showApp();
  } else {
    $('login-error').style.display = 'block';
    setTimeout(() => $('login-error').style.display='none', 3000);
  }
}

$('logout-btn').onclick = () => {
  state.user = null; save();
  $('app').style.display = 'none';
  $('login-screen').style.display = 'flex';
};

function showApp() {
  $('login-screen').style.display = 'none';
  $('app').style.display = 'block';
  $('user-name').textContent = state.user.name;
  $('user-email').textContent = state.user.email;
  $('user-avatar').textContent = state.user.name[0].toUpperCase();
  seedDemoEvents();
  navTo('dashboard');
  startReminderLoop();
}

// ── 데모 이벤트 시딩 ────────────────────────────────────────
function seedDemoEvents() {
  if (state.events.length) return;
  const t = new Date();
  const ymd = (d,h,m) => {
    const x=new Date(d); x.setHours(h,m,0);
    const base = fmtDate(x);
    return { date: base, time: `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}` };
  };
  const addEv = (title,d,h,m,eh,em,color,repeat,memo,cat) => {
    const {date,time}=ymd(t,h,m);
    addEvent({title,date,time,endTime:`${String(eh).padStart(2,'0')}:${String(em).padStart(2,'0')}`,color:color||0,repeat:repeat||'none',reminder:true,memo:memo||'',category:cat||'업무'});
  };
  addEv('팀 스크럼 회의',t,9,0,9,30,0,'weekday','매일 오전 스탠드업','업무');
  addEv('Azure 인프라 설계',t,10,0,12,0,3,'none','VNet, Subnet 설계 마무리','업무');
  addEv('점심 식사',t,12,0,13,0,1,'weekday','','개인');
  addEv('Terraform 코드 작성',t,14,0,17,0,2,'none','VMSS 모듈 완성 목표','업무');

  const tom = new Date(t); tom.setDate(tom.getDate()+1);
  addEv('DB 모듈 배포',tom,10,0,11,30,4,'none','MySQL Zone-HA 배포','업무');
  addEv('운동',tom,19,0,20,0,1,'weekly','헬스장','건강');

  // 할 일 시딩
  if (!state.todos.length) {
    ['Terraform provider.tf 작성','VNet 서브넷 설계 검토','팀원 PR 리뷰','Azure 포털 접속 확인'].forEach(t => {
      state.todos.push({ id: state.nextId++, title: t, date: today(), done: false });
    });
    save();
  }
}

// ── 네비게이션 ──────────────────────────────────────────────
document.querySelectorAll('.nav-item').forEach(item => {
  item.onclick = () => navTo(item.dataset.page);
});

function navTo(page) {
  document.querySelectorAll('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.page===page));
  document.querySelectorAll('.page').forEach(p => p.classList.toggle('active', p.id===`page-${page}`));
  if (page==='dashboard') renderDashboard();
  if (page==='calendar') renderCalendar();
  if (page==='todos') renderTodos();
}

// ── 이벤트 CRUD ─────────────────────────────────────────────
function addEvent(data) {
  const ev = { id: state.nextId++, ...data };
  state.events.push(ev);
  save();
  return ev;
}

function getEventsForDate(dateStr) {
  return state.events.filter(ev => {
    if (ev.repeat === 'none') return ev.date === dateStr;
    return isRepeatingOn(ev, dateStr);
  });
}

function isRepeatingOn(ev, dateStr) {
  const start = new Date(ev.date + 'T00:00:00');
  const check = new Date(dateStr + 'T00:00:00');
  if (check < start) return false;
  if (ev.repeatEnd && check > new Date(ev.repeatEnd + 'T00:00:00')) return false;
  if (ev.repeat === 'daily') return true;
  if (ev.repeat === 'weekly') return check.getDay() === start.getDay();
  if (ev.repeat === 'monthly') return check.getDate() === start.getDate();
  if (ev.repeat === 'weekday') { const d=check.getDay(); return d>=1&&d<=5; }
  return false;
}

// ── 모달 ────────────────────────────────────────────────────
let editingEventId = null;
let selectedColor = 0;

function openModal(prefillDate) {
  editingEventId = null;
  $('modal-title-text').textContent = '새 일정 추가';
  $('ev-title').value = '';
  $('ev-date').value = prefillDate || today();
  $('ev-time').value = '09:00';
  $('ev-end-time').value = '10:00';
  $('ev-category').value = '업무';
  $('ev-repeat').value = 'none';
  $('ev-repeat-end').value = '';
  $('ev-reminder').checked = true;
  $('ev-memo').value = '';
  $('ev-delete-btn').style.display = 'none';
  setColorSwatch(0);
  $('repeat-end-wrap').style.display = 'none';
  $('event-modal').classList.add('open');
  $('ev-title').focus();
}

function openEditModal(ev) {
  editingEventId = ev.id;
  $('modal-title-text').textContent = '일정 수정';
  $('ev-title').value = ev.title;
  $('ev-date').value = ev.date;
  $('ev-time').value = ev.time || '';
  $('ev-end-time').value = ev.endTime || '';
  $('ev-category').value = ev.category || '업무';
  $('ev-repeat').value = ev.repeat || 'none';
  $('ev-repeat-end').value = ev.repeatEnd || '';
  $('ev-reminder').checked = !!ev.reminder;
  $('ev-memo').value = ev.memo || '';
  $('ev-delete-btn').style.display = 'inline-flex';
  setColorSwatch(ev.color || 0);
  $('repeat-end-wrap').style.display = ev.repeat !== 'none' ? 'flex' : 'none';
  $('event-modal').classList.add('open');
}

function closeModal() { $('event-modal').classList.remove('open'); }

function setColorSwatch(idx) {
  selectedColor = idx;
  document.querySelectorAll('.color-swatch').forEach(s => s.classList.toggle('active', +s.dataset.color===idx));
}

document.querySelectorAll('.color-swatch').forEach(s => s.onclick = () => setColorSwatch(+s.dataset.color));
$('ev-repeat').onchange = () => { $('repeat-end-wrap').style.display = $('ev-repeat').value!=='none'?'flex':'none'; };
$('modal-close').onclick = closeModal;
$('modal-cancel').onclick = closeModal;
$('event-modal').onclick = e => { if(e.target===$('event-modal')) closeModal(); };
$('btn-new-event').onclick = () => openModal();
$('btn-new-event2').onclick = () => openModal(calState.selectedDate || today());

$('ev-save-btn').onclick = () => {
  const title = $('ev-title').value.trim();
  if (!title) { $('ev-title').style.borderColor='var(--red)'; setTimeout(()=>$('ev-title').style.borderColor='',1500); return; }
  const data = {
    title, date: $('ev-date').value, time: $('ev-time').value,
    endTime: $('ev-end-time').value, color: selectedColor,
    category: $('ev-category').value, repeat: $('ev-repeat').value,
    repeatEnd: $('ev-repeat-end').value || null,
    reminder: $('ev-reminder').checked, memo: $('ev-memo').value,
  };
  if (editingEventId !== null) {
    const idx = state.events.findIndex(e => e.id===editingEventId);
    if (idx >= 0) { state.events[idx] = { id: editingEventId, ...data }; save(); }
  } else {
    addEvent(data);
  }
  fetch('?api=add_event', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  .then(res => res.json())
  .then(resData => {
    if(resData.status === 'success') {
       console.log("MySQL 데이터베이스에 일정이 동기화되었습니다.");
    }
  })
  .catch(err => console.error("DB 전송 실패:", err));

  closeModal();
  refreshCurrentPage();
  showToast('info','일정 저장됨', `"${title}" 저장되었습니다.`);
};

$('ev-delete-btn').onclick = () => {
  if (!confirm('이 일정을 삭제할까요?')) return;

  // 1. 현재 지우려고 하는 일정의 상세 정보(title, date 등)를 미리 찾습니다.
  const targetEvent = state.events.find(e => e.id === editingEventId);
  
  if (!targetEvent) {
    showToast('error', '오류', '삭제할 일정을 찾을 수 없습니다.');
    return;
  }

  // 2. 서버(MySQL)에 삭제 요청 보내기
  fetch('?api=delete_event', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: targetEvent.title,
      date: targetEvent.date
    })
  })
  .then(res => res.json())
  .then(resData => {
    if (resData.status === 'success') {
      console.log("MySQL 데이터베이스에서 일정이 삭제되었습니다.");
    } else {
      console.error("서버 삭제 실패:", resData.message);
    }
  })
  .catch(err => console.error("DB 전송 실패:", err));

  // 3. 로컬 화면 및 상태 업데이트 (기존 코드 유지)
  state.events = state.events.filter(e => e.id !== editingEventId);
  save(); 
  closeModal(); 
  refreshCurrentPage();
  
  showToast('info', '삭제됨', '일정이 삭제되었습니다.');
};

function refreshCurrentPage() {
  const active = document.querySelector('.nav-item.active');
  if (active) navTo(active.dataset.page);
}

// ── 캘린더 ──────────────────────────────────────────────────
const calState = { year: new Date().getFullYear(), month: new Date().getMonth(), selectedDate: today() };

function renderCalendar() {
  const { year, month } = calState;
  $('cal-month-label').textContent = `${year}년 ${MONTHS_KO[month]}`;
  const headers = $('cal-day-headers');
  headers.innerHTML = '';
  DAYS_KO.forEach(d => { const h=el('div','cal-day-header'); h.textContent=d; headers.appendChild(h); });

  const body = $('cal-body');
  body.innerHTML = '';
  const first = new Date(year, month, 1);
  const last  = new Date(year, month+1, 0);
  const pad   = first.getDay();

  for (let i=0; i<pad; i++) {
    const prev = new Date(year, month, -pad+i+1);
    addCalDay(body, prev, true);
  }
  for (let d=1; d<=last.getDate(); d++) addCalDay(body, new Date(year, month, d), false);
  const remain = 7 - ((pad + last.getDate()) % 7);
  if (remain < 7) for (let d=1; d<=remain; d++) addCalDay(body, new Date(year, month+1, d), true);

  renderDayPanel(calState.selectedDate);
}

function addCalDay(container, date, otherMonth) {
  const dateStr = fmtDate(date);
  const isToday = dateStr === today();
  const isSelected = dateStr === calState.selectedDate;
  const div = el('div', `cal-day${otherMonth?' other-month':''}${isSelected?' selected':''}`);
  const numWrap = el('div', 'day-num');
  numWrap.textContent = date.getDate();
  if (isToday) div.classList.add('today');
  div.appendChild(numWrap);

  const evs = getEventsForDate(dateStr);
  const maxShow = 2;
  evs.slice(0, maxShow).forEach(ev => {
    const dot = el('div', `event-dot color-${ev.color}`);
    dot.textContent = ev.time ? `${ev.time} ${ev.title}` : ev.title;
    dot.onclick = e => { e.stopPropagation(); openEditModal(ev); };
    div.appendChild(dot);
  });
  if (evs.length > maxShow) {
    const more = el('div','more-dots');
    more.textContent = `+${evs.length-maxShow}개 더`;
    div.appendChild(more);
  }
  div.onclick = () => {
    calState.selectedDate = dateStr;
    document.querySelectorAll('.cal-day').forEach(d => d.classList.remove('selected'));
    div.classList.add('selected');
    renderDayPanel(dateStr);
  };
  container.appendChild(div);
}

function renderDayPanel(dateStr) {
  const date = new Date(dateStr + 'T00:00:00');
  $('day-panel-title').textContent = fmtDateKo(date);
  const panel = $('day-panel-events');
  panel.innerHTML = '';
  const evs = getEventsForDate(dateStr).sort((a,b)=>(a.time||'').localeCompare(b.time||''));
  if (!evs.length) {
    const es = el('div','empty-state');
    es.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>일정이 없습니다';
    panel.appendChild(es);
    return;
  }
  evs.forEach(ev => {
    const item = el('div','day-event-item');
    item.style.borderLeftColor = COLORS[ev.color] || COLORS[0];
    const time = el('div','dei-time');
    time.textContent = ev.time ? (ev.endTime ? `${ev.time}?${ev.endTime}` : ev.time) : '종일';
    const info = el('div','dei-info');
    const title = el('div','dei-title'); title.textContent = ev.title;
    const tags = el('div','dei-tags');
    if (ev.repeat !== 'none') { const t=el('span','tag-pill repeat-tag'); t.textContent='반복'; tags.appendChild(t); }
    if (ev.reminder) { const t=el('span','tag-pill reminder-tag'); t.textContent='알림'; tags.appendChild(t); }
    info.appendChild(title); info.appendChild(tags);
    item.appendChild(time); item.appendChild(info);
    item.onclick = () => openEditModal(ev);
    panel.appendChild(item);
  });
}

$('cal-prev').onclick = () => { calState.month--; if(calState.month<0){calState.month=11;calState.year--;} renderCalendar(); };
$('cal-next').onclick = () => { calState.month++; if(calState.month>11){calState.month=0;calState.year++;} renderCalendar(); };
$('cal-today-btn').onclick = () => { const n=new Date(); calState.year=n.getFullYear(); calState.month=n.getMonth(); calState.selectedDate=today(); renderCalendar(); };

// ── 할 일 ──────────────────────────────────────────────────
function getTodayTodos() { return state.todos.filter(t => t.date === today()); }
function getEventTodos() {
  return getEventsForDate(today()).map(ev => ({
    id: 'ev_' + ev.id, title: ev.title,
    date: today(), done: !!ev._todoDone,
    time: ev.time, isEvent: true, color: ev.color,
  }));
}

function renderTodos() {
  const d = new Date();
  $('todo-date-label').textContent = fmtDateKo(d);
  const manualTodos = getTodayTodos();
  const eventTodos  = getEventTodos();
  const allTodos    = [...eventTodos, ...manualTodos];
  const done = allTodos.filter(t => t.done).length;
  $('todo-badge').textContent = `${done} / ${allTodos.length} 완료`;
  const pct = allTodos.length ? Math.round(done/allTodos.length*100) : 0;
  $('todo-progress').style.width = pct + '%';
  $('todo-pct').textContent = pct + '%';

  const body = $('todo-body');
  body.innerHTML = '';

  if (eventTodos.length) {
    const sec = el('div','todo-section');
    const stitle = el('div','todo-section-title'); stitle.textContent = '오늘 일정';
    sec.appendChild(stitle);
    eventTodos.forEach(t => sec.appendChild(makeTodoItem(t)));
    body.appendChild(sec);
  }

  const sec2 = el('div','todo-section');
  const stitle2 = el('div','todo-section-title'); stitle2.textContent = '할 일 목록';
  sec2.appendChild(stitle2);
  if (manualTodos.length) {
    manualTodos.forEach(t => sec2.appendChild(makeTodoItem(t)));
  } else {
    const es = el('div','empty-state'); es.style.paddingTop='16px';
    es.textContent = '할 일을 추가해 보세요!';
    sec2.appendChild(es);
  }
  body.appendChild(sec2);
}

function makeTodoItem(t) {
  const item = el('div', `todo-item${t.done?' done':''}`);
  const check = el('div', `todo-check${t.done?' checked':''}`);
  const dot = el('div','todo-color');
  dot.style.background = COLORS[t.color||0];
  const title = el('div','todo-title'); title.textContent = t.title;
  const time = el('div','todo-time'); time.textContent = t.time || '';
  check.onclick = () => toggleTodo(t);
  item.appendChild(check);
  item.appendChild(dot);
  item.appendChild(title);
  item.appendChild(time);
  return item;
}

function toggleTodo(t) {
  if (t.isEvent) {
    const ev = state.events.find(e => e.id === +t.id.replace('ev_',''));
    if (ev) { ev._todoDone = !ev._todoDone; save(); }
  } else {
    const todo = state.todos.find(x => x.id === t.id);
    if (todo) { todo.done = !todo.done; save(); }
  }
  renderTodos();
  if (document.querySelector('#page-dashboard.active')) renderDashboard();
}

function addQuickTodo(title) {
  if (!title.trim()) return;
  state.todos.push({ id: state.nextId++, title: title.trim(), date: today(), done: false });
  save(); renderTodos();
}

$('add-todo-btn').onclick = () => { addQuickTodo($('add-todo-input').value); $('add-todo-input').value=''; };
$('add-todo-input').onkeydown = e => { if(e.key==='Enter'){addQuickTodo($('add-todo-input').value);$('add-todo-input').value='';} };

// ── 대시보드 ─────────────────────────────────────────────────
function renderDashboard() {
  const d = new Date();
  $('dash-date-label').textContent = fmtDateKo(d);

  const todayEvs = getEventsForDate(today());
  $('stat-today').textContent = todayEvs.length;

  const allTodos = [...getEventTodos(), ...getTodayTodos()];
  const done = allTodos.filter(t=>t.done).length;
  $('stat-done').textContent = done;
  $('stat-done-sub').textContent = `오늘 총 ${allTodos.length}개`;

  const weekEvs = getWeekEvents();
  $('stat-week').textContent = weekEvs.length;

  const upcoming = $('upcoming-list-body');
  upcoming.innerHTML = '';
  const next7 = [];
  for (let i=0; i<=7; i++) {
    const dd = new Date(); dd.setDate(dd.getDate()+i);
    const ds = fmtDate(dd);
    getEventsForDate(ds).forEach(ev => next7.push({...ev, _displayDate: ds}));
  }
  next7.sort((a,b)=>(a._displayDate+a.time).localeCompare(b._displayDate+b.time)).slice(0,6).forEach(ev => {
    const item = el('div','ul-item');
    const dot = el('div','ul-dot'); dot.style.background=COLORS[ev.color]||COLORS[0];
    const info = el('div','ul-info');
    const title = el('div','ul-title'); title.textContent = ev.title;
    const date  = el('div','ul-date');
    const isToday2 = ev._displayDate===today();
    const isTomorrow = ev._displayDate===fmtDate(new Date(Date.now()+86400000));
    date.textContent = (isToday2?'오늘 ':isTomorrow?'내일 ':ev._displayDate+' ') + (ev.time||'');
    info.appendChild(title); info.appendChild(date);
    const badges = el('div',null);
    if(ev.repeat!=='none'){const b=el('span','ul-badge');b.textContent='반복';badges.appendChild(b);}
    item.appendChild(dot); item.appendChild(info); item.appendChild(badges);
    item.onclick = () => { calState.selectedDate=ev._displayDate; calState.year=+ev._displayDate.slice(0,4); calState.month=+ev._displayDate.slice(5,7)-1; navTo('calendar'); };
    upcoming.appendChild(item);
  });
  if (!next7.length) {
    upcoming.innerHTML = '<div class="empty-state" style="padding:24px">다가오는 일정이 없습니다</div>';
  }
}

function getWeekEvents() {
  const result = [];
  for (let i=0;i<7;i++){const d=new Date();d.setDate(d.getDate()+i);result.push(...getEventsForDate(fmtDate(d)));}
  return result;
}

// ── 알림 ───────────────────────────────────────────────────
const notified = new Set();
function startReminderLoop() {
  checkReminders();
  setInterval(checkReminders, 30000);
}

function checkReminders() {
  const now = new Date();
  const dateStr = fmtDate(now);
  const evs = getEventsForDate(dateStr);
  evs.forEach(ev => {
    if (!ev.reminder || !ev.time) return;
    const [h,m] = ev.time.split(':').map(Number);
    const evTime = new Date(now); evTime.setHours(h,m,0,0);
    const diff = (evTime - now) / 60000;
    const key = `${ev.id}_${dateStr}`;
    if (diff > 0 && diff <= 10 && !notified.has(key)) {
      notified.add(key);
      showToast('reminder', '일정 알림', `"${ev.title}" 시작 ${Math.round(diff)}분 전`);
    }
  });
}

function showToast(type, title, msg) {
  const wrap = $('toast-wrap');
  const toast = el('div',`toast ${type}`);
  const icon = el('span','toast-icon'); icon.textContent = type==='reminder'?'?':'?';
  const body = el('div','toast-body');
  const t = el('div','toast-title'); t.textContent = title;
  const m = el('div','toast-msg'); m.textContent = msg;
  const close = el('button','toast-close'); close.textContent='?';
  body.appendChild(t); body.appendChild(m);
  toast.appendChild(icon); toast.appendChild(body); toast.appendChild(close);
  wrap.appendChild(toast);
  const remove = () => { toast.style.opacity='0'; toast.style.transform='translateX(20px)'; toast.style.transition='.3s'; setTimeout(()=>toast.remove(),300); };
  close.onclick = remove;
  setTimeout(remove, 5000);
}

// ── 앱 초기화 ──────────────────────────────────────────────
if (state.user) showApp();
</script>
</body>
</html>
EOF
systemctl enable --now httpd