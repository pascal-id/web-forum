# Pascal Indonesia Web Forum

[![Website](https://img.shields.io/badge/web-pascal--dev.org-blue)](https://www.pascal-dev.org)
[![Built with FastPlaz](https://img.shields.io/badge/built%20with-FastPlaz-orange)](https://github.com/fastplaz/fastplaz)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**English** | [Bahasa Indonesia](README-id.md)

![Pascal Indonesia](docs/web.png)

The source code of [pascal-dev.org](https://www.pascal-dev.org), the website of the
**Indonesian Object Pascal Programmers Community**: a forum, articles/news, and search,
plus a JSON API. It is written in Object Pascal with
[FastPlaz](https://github.com/fastplaz/fastplaz), a web framework for Free Pascal.

## Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Building](#building)
- [Web Routes](#web-routes)
- [API](#api)
- [Deployment Notes](#deployment-notes)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Forum**: categories, topic lists, threads, and new topics.
- **Articles / News**: article list and detail pages (with Markdown content), writing new articles, and reporting an article as obsolete.
- **Search** across articles and forum posts.
- **Authentication**: login/logout, Facebook login, and token-based login.
- **User profiles**.
- **JSON API** for forum, news, topics, statistics, and authentication.
- **SEO**: friendly URLs (`/news/{id}/{slug}`), Open Graph meta tags, and `sitemap.xml`.
- Responsive theme based on AdminLTE / Bootstrap.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Object Pascal (Free Pascal 3.2.x) |
| Framework | [FastPlaz](https://github.com/fastplaz/fastplaz) |
| Database | MySQL (5.6 or later, 8.0 tested) |
| Web server | Apache 2.4 or LiteSpeed, running the apps as CGI (`.bin`) with `mod_rewrite` |
| Front end | AdminLTE, Bootstrap, jQuery, Font Awesome, Summernote, Toastr |

## Project Structure

```
web-forum/
├── docs/                   # documentation & screenshot
│   └── api/                # API documentation (Forum, News, Topics)
├── public_html/            # document root of the website
│   ├── *.bin               # compiled web apps: forumpascal, auth, search
│   ├── api/                # document root of the API (*.bin, config, .htaccess)
│   ├── config/             # config.json (not in git), config.json-example
│   ├── modules/            # per-module templates, css & js
│   ├── themes/             # PascalIndonesia (default theme), default
│   ├── files/              # uploaded files
│   └── ztemp/              # cache, sessions, error log
└── source/
    ├── common/             # shared code: models, controllers, common_lib
    ├── web/                # web apps: forumpascal.lpr, auth.lpr, search.lpr
    │   ├── controllers/
    │   └── routes/
    └── api/                # API apps: forum, news, topic, stats, auth
        ├── controllers/
        └── routes/
```

Each `.lpr` file is a separate program. It is compiled into a `.bin` (CGI)
in `public_html/` (web) or `public_html/api/` (API).

## Requirements

- [Free Pascal](https://www.freepascal.org/) 3.2.x. [Lazarus](https://www.lazarus-ide.org/) is optional, for editing (`.lpi` project files).
- [FastPlaz](https://github.com/fastplaz/fastplaz) source code.
- MySQL server and its client library (`libmysqlclient` / `libmysql.dll`).
- Apache 2.4 (or LiteSpeed) with CGI and `mod_rewrite` enabled, and `AllowOverride All` for `public_html`.

## Getting Started

1. **Place the source next to FastPlaz.** The compiler options (`extra.cfg`) look for
   FastPlaz at `../../../vendors/fastplaz`, so the expected layout is:

   ```
   <workspace>/
   ├── vendors/
   │   └── fastplaz/        # git clone https://github.com/fastplaz/fastplaz.git (a symlink is fine)
   └── web-forum/           # this repository
   ```

2. **Create the database** in MySQL. The database schema is not included in this repository.

3. **Create the configuration** for the web and the API:

   ```bash
   cp public_html/config/config.json-example public_html/config/config.json
   # public_html/api/config/config.json for the API
   ```

   Then fill in the database settings (see [Configuration](#configuration)).

4. **Build** the apps (see [Building](#building)).

5. **Set up a virtual host** whose document root is `public_html/`,
   for example `http://pascal-dev.test`. The included `.htaccess` sends the
   requests to the right `.bin`.

## Configuration

`public_html/config/config.json` (and `public_html/api/config/config.json` for the API).
These files hold credentials and are ignored by git.

| Key | Description |
|---|---|
| `systems/baseurl` | Base URL of the site, e.g. `http://pascal-dev.test/` |
| `systems/theme` | Theme name, `PascalIndonesia` |
| `systems/development`, `systems/debug` | Development/debug mode |
| `systems/session_storage` | Where sessions are stored, e.g. `database` |
| `database/default/driver` | e.g. `MySQL 8.0` |
| `database/default/hostname`, `port`, `username`, `password`, `database_name` | Database connection |
| `database/default/charset` | Connection charset. Leave it empty to use FastPlaz's default (`utf8mb4` for MySQL). |
| `database/default/library` | Path to the MySQL client library, if it is not on the system path |
| `image/sourceBaseURL` | Base URL of the image CDN |
| `mailer/default/*` | SMTP settings |

## Building

The build scripts compile every program with `fpc` and the options in `extra.cfg`.

```bash
# web apps -> public_html/*.bin
cd source/web
./build.sh forumpascal      # one program
./build-all.sh              # auth, forumpascal, search

# API apps -> public_html/api/*.bin
cd source/api
./build.sh news
./build-all.sh              # forum, news, stats, topic, auth
```

On Windows, run the scripts from Git Bash. `clean.sh` removes the compiled units.

**Building for older Linux hosting.** A binary built on a recent distro needs a
recent glibc and may fail (HTTP 500) on hosting with an older glibc (e.g. cPanel/CloudLinux 8).
`build-docker.sh` builds inside a Docker image with an older glibc:

```bash
./build-docker.sh forumpascal      # incremental build
./build-docker.sh all              # every *.lpr
```

You can also open `source/WEB.lpg` or `source/API.lpg` (project groups) in Lazarus.

## Web Routes

| Path | Description |
|---|---|
| `/` | Home page |
| `/forum` | Forum index |
| `/forum/category/{id}/{slug}` | Forum category |
| `/forum/{id}/{slug}` | Topic list of a forum |
| `/forum/{id}/{slug}/new/` | New topic |
| `/thread/{forum}/{id}/{slug}` | Thread |
| `/news/`, `/article/` | Article list |
| `/news/{id}/{slug}` | Article detail |
| `/news/new/` | New article |
| `/obsolete/` | Report an article as obsolete |
| `/profile/{username}` | User profile |
| `/user` | User page |
| `/auth/...` | Login, logout, Facebook login, token (`auth.bin`) |
| `/search/` | Search (`search.bin`) |

## API

The API lives in `public_html/api/`. Every response is JSON:

```json
{ "code": 0, "count": 1, "data": [ ... ] }
```

| Endpoint | Description |
|---|---|
| `GET /news/` | News list |
| `GET /news/last/?limit=n` | Latest news |
| `GET /news/{id}/{slug}` | News detail |
| `GET /news/search/` | Search news |
| `GET /forum/` | Forum list |
| `GET /topic/recent/` | Recent topics |
| `GET /topic/last/` | Latest topics |
| `GET /topic/thread/{id}/{slug}/` | Thread |
| `GET /topic/search/` | Search topics |
| `GET /stats/` | Statistics |
| `/auth/` | Authentication |

The full documentation, with parameters and response examples, is in [docs/api](docs/api):
[Forum](docs/api/Forum.md), [News](docs/api/News.md), [Topics](docs/api/Topics.md).

## Deployment Notes

- Upload the compiled `.bin` files and `public_html/` to the server. Do not upload your local `config.json`; use the server's own.
- The `.htaccess` files under `public_html/modules/` use `mod_rewrite` to serve only static
  assets (css, js, images, fonts). The old `deny from all` + `<FilesMatch>` rule does not
  work on LiteSpeed.
- On Windows (development), FastPlaz sets the default code page to UTF-8, so text from the
  database is shown correctly. Make sure you build with an up-to-date FastPlaz.
- If the site is behind Cloudflare, purge the cache after changing css/js.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md):

1. Fork this repository.
2. Create a feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push the branch: `git push origin my-new-feature`
5. Open a Pull Request.

Bug reports and feature requests: use the issue templates in this repository.

## License

[MIT](LICENSE) © 2019 Pascal Indonesia
