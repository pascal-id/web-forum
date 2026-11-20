# Security TODO

Hasil audit keamanan source `web-forum` (web + api + common) tanggal 2026-11-20.

Legenda: `[ ]` belum, `[x]` selesai, `[~]` sebagian.

Catatan konteks:
- FastPlaz meng-escape `_GET` / `_POST` otomatis (`Sanitize := True`, `mysql_real_escape_string`),
  tetapi **tidak** untuk `Header[...]`, `GetEnvironmentVariable(...)`, `Request.Content` (JSON body),
  dan data yang dibaca dari database.
- `XSSProof := False`, dan `ThemeUtil.Assign` / filter `multifilter` **tidak** meng-escape HTML.
- `TSimpleModel.Save` memakai parameter (`:field`), jadi nilai lewat `Value[...]` aman dari SQLi.

---

## 🔴 Kritis

### 1. Login Facebook tidak memverifikasi token (account takeover)
- File: `source/web/controllers/auth_facebook_controller.pas` (`Post`)
- Masalah: header `Token` dan JSON body (`email`, `id`, nama) dipercaya mentah-mentah.
  `POST /auth/facebook/` dengan `Token: apa-saja` + `{"email":"<email korban>"}` → login sebagai korban.
- Perbaikan:
  - [x] Validasi format token (hanya karakter `[A-Za-z0-9_.-]`).
  - [x] Verifikasi token ke Graph API: `GET /app` → app id harus sama dengan app id situs
        (config `facebook/app_id`, default konstanta `FACEBOOK_APP_ID`).
  - [x] Ambil `id`, `first_name`, `last_name`, `email` dari `GET /me` (Graph API), bukan dari request body.
  - [x] Bug tambahan: user baru dari Facebook mendapat `user_id` = `LastInsertID` **setelah**
        insert ke `user_mapping` (jadi id mapping, bukan `users.uid`) → bisa login sebagai user lain.
        Sekarang memakai `TUserModel.NewUserId`.
  - [ ] Tes manual login Facebook dengan akun asli (alur sukses belum bisa dites otomatis).
  - Implementasi: `source/common/facebook_lib.pas`.

### 2. SQL injection via header `Token`
- File: `source/common/models/auth_token_model.pas` (`IsValid`), dipanggil dari
  `web/controllers/auth_facebook_controller.pas`, `web/controllers/auth_token_controller.pas`,
  `api/controllers/auth_facebook_controller.pas`.
- Perbaikan:
  - [x] Tolak token yang formatnya tidak valid di controller (400).
  - [x] Escape token di `IsValid` (defense in depth).

### 3. SQL injection via data login Facebook
- File: `source/common/models/auth_user_model.pas` (`FindByEmail`, `isMappingExist`),
  `source/common/models/user_model.pas` (`AddFromFacebook`, `AddMapping`).
- Perbaikan:
  - [x] Escape semua string yang digabung ke SQL di fungsi-fungsi tersebut.
  - [x] `facebook id` harus numerik.

## 🟠 Tinggi

### 4. Stored XSS (reply thread, topik baru, signature, artikel)
- File: `web/controllers/thread_controller.pas:153`, `web/controllers/topic_new_controller.pas:118`,
  `web/controllers/article_new_controller.pas`, `web/controllers/article_detail_controller.pas`,
  template `modules/forum/thread.html` (`filter=multifilter`), `modules/user/profile.html`.
- Masalah: konten disimpan setelah `UrlDecode` dan ditampilkan sebagai HTML tanpa escaping/sanitizer.
- Implementasi: `source/common/html_sanitizer_lib.pas` (`SafeHTML`, whitelist tag/atribut).
- [x] Sanitasi HTML hasil render BBCode/markdown (whitelist tag & atribut, buang `on*`,
      `<script>/<iframe>/<svg>/...`, style berbahaya).
- [x] Tolak skema selain `http/https/mailto/ftp` di `href`/`src` (termasuk yang di-encode entity).
- [x] Post thread: `TTopicModel.Thread` (dipakai halaman thread **dan** `api/topic/thread`);
      template `thread.html` kini memakai data JSON yang sudah disanitasi (bukan `filter=multifilter`).
- [x] Artikel: `$HomeText` / `$BodyText` di `article_detail_controller.pas`.
- [x] Signature profil (`profile_controller.pas`, `profile.html`).
- [x] `[` / `]` di konten di-escape agar tidak diproses ulang sebagai tag template FastPlaz.
- [x] Judul topik/artikel/obsolete baru: `< > "` di-encode saat disimpan (`CleanTitle`).
- [x] Username baru dari Facebook: karakter `<>"'&\/[]` dan spasi dibuang.
- [ ] Tes visual konten lama (BBCode/HTML legacy) di halaman thread & artikel — dev server
      belum bisa (DB error: library MySQL tidak ter-load).
- [ ] Catatan: atribut `onerror` bawaan `[img]` (sembunyikan gambar rusak) ikut terbuang.

### 5. Membuat artikel / topik tanpa login
- [x] `web/controllers/article_new_controller.pas` (`Post`): wajib login (401).
- [x] `web/controllers/topic_new_controller.pas` (`Post`): wajib login (401).
- [x] Forum harus `auth_read=0`, `forum_status=0`, `auth_post<=1` (403).
- [ ] Reply (`thread_controller.pas` `Post`) belum mengecek topik ada / tidak dikunci / forumnya boleh reply.

### 6. Reflected XSS di halaman search
- [x] `web/controllers/search_controller.pas`: `$Query` dan `$Title` di-encode HTML
      (terverifikasi di dev: `"><script>` kini keluar sebagai `&quot;&gt;&lt;script&gt;`).
- [x] `modules/search/js/search.js`: keyword & riwayat pencarian di-escape sebelum `.html()`.
- [ ] Cek nilai lain yang di-`Assign` dari input user / DB (`$Title` di thread, profile, dll) —
      judul lama dari DB sudah ter-encode (phpBB), judul baru via `CleanTitle`.

## 🟡 Sedang

- [ ] 7. Draft artikel bisa dilihat siapa saja via `?preview=1`
      (`article_detail_controller.pas`, `TODO: check permission`) → batasi ke kontributor/admin.
- [ ] 8. Tidak ada CSRF token di POST/PUT (reply, topik baru, edit artikel, obsolete, logout).
- [ ] 9. Second-order SQLi: username dari DB digabung ke SQL (`user_model.pas` `getArticleCount`).
- [ ] 10. Hak edit artikel dicek via string username, sebaiknya via user id.
- [ ] 11. `Access-Control-Allow-Origin: *` di `public_html/api/.htaccess` — pastikan API tidak pernah
      memakai cookie/session; batasi origin bila perlu.

## ✅ Sudah aman

- `config/`, `ztemp/`, `files/` (termasuk di `api/`) ditutup `.htaccess` (`deny from all`).
- Parameter angka dari URL di-cast `AsInteger` / `ToInteger`.
- Nilai Open Graph sudah `HTMLEncode`.
