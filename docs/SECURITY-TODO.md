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
- [ ] Escape HTML konten user sebelum BBCode/markdown di-render (atau sanitizer whitelist tag).
- [ ] Tolak skema `javascript:` / `data:` di `[url=...]`, `[img]`, link markdown.

### 5. Membuat artikel / topik tanpa login
- [ ] `web/controllers/article_new_controller.pas` (`Post`): wajib login.
- [ ] `web/controllers/topic_new_controller.pas` (`Post`): wajib login (`UserSession.IsExpired`).
- [ ] Cek forum boleh di-post (`auth_post`), bukan hanya `auth_read`.

### 6. Reflected XSS di halaman search
- [ ] `web/controllers/search_controller.pas`: `HTMLEncode` untuk `$Query` dan `$Title`.
- [ ] Cek nilai lain yang di-`Assign` dari input user / DB (`$Title` di thread, profile, dll).

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
