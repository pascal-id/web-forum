unit html_sanitizer_lib;

{
  Sanitizer HTML berbasis whitelist untuk konten buatan user
  (post forum, artikel, signature) SETELAH BBCode/markdown di-render.

  - Tag yang diizinkan ditulis ulang hanya dengan atribut yang diizinkan.
  - Atribut event (on*), style berbahaya, dan URL dengan skema selain
    http/https/mailto/ftp (javascript:, data:, vbscript:, ...) dibuang.
  - <script>, <style>, <iframe>, ... dibuang beserta isinya.
  - Tag lain dibuang, teks di dalamnya dipertahankan.
  - '<' / '>' yang bukan tag di-escape.
  - '[' dan ']' di-escape (&#91; &#93;) agar tidak diproses ulang
    oleh template engine FastPlaz (tag [..]).

  USAGE:
    html := SafeHTML(MarkdownToHTML(FormatTextLikeForum(text)));
    s    := EscapeHTMLText(plainText);
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

function SafeHTML(const AHTML: string): string;
function EscapeHTMLText(const AText: string): string;
function IsSafeURL(const AURL: string): boolean;
function CleanTitle(const ATitle: string): string;

implementation

// judul (topik/artikel) ditampilkan mentah di banyak tempat (HTML, atribut,
// string JS, JSON API); disimpan dengan < > " sudah di-encode, sama seperti
// data lama phpBB (htmlspecialchars). '&' dibiarkan agar entity lama tidak rusak.
function CleanTitle(const ATitle: string): string;
begin
  Result := Trim(ATitle);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
end;

const
  ALLOWED_TAGS: array[0..50] of string = (
    'a', 'abbr', 'b', 'big', 'blockquote', 'br', 'caption', 'center', 'cite',
    'code', 'col', 'colgroup', 'dd', 'del', 'div', 'dl', 'dt', 'em',
    'figcaption', 'figure', 'font', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr',
    'i', 'img', 'ins', 'kbd', 'li', 'mark', 'ol', 'p', 'pre', 'q', 's', 'samp',
    'small', 'span', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td',
    'tt', 'u');
  ALLOWED_TAGS_2: array[0..5] of string = (
    'tfoot', 'th', 'thead', 'tr', 'ul', 'var');

  // dibuang beserta isinya
  DROP_CONTENT_TAGS: array[0..14] of string = (
    'script', 'style', 'iframe', 'object', 'embed', 'applet', 'noscript',
    'template', 'textarea', 'title', 'xmp', 'svg', 'math', 'frameset',
    'noembed');

  VOID_TAGS: array[0..4] of string = ('br', 'hr', 'img', 'col', 'wbr');

  ALLOWED_ATTRS: array[0..18] of string = (
    'href', 'src', 'title', 'alt', 'class', 'width', 'height', 'align',
    'valign', 'colspan', 'rowspan', 'lang', 'color', 'size', 'face',
    'target', 'style', 'border', 'start');

  URL_ATTRS: array[0..1] of string = ('href', 'src');

function InList(const AValue: string; const AList: array of string): boolean;
var
  i: integer;
begin
  Result := False;
  for i := Low(AList) to High(AList) do
    if AList[i] = AValue then
      Exit(True);
end;

function IsAllowedTag(const AName: string): boolean;
begin
  Result := InList(AName, ALLOWED_TAGS) or InList(AName, ALLOWED_TAGS_2);
end;

function EscapeHTMLText(const AText: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(AText) do
    case AText[i] of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&#39;';
    else
      Result := Result + AText[i];
    end;
end;

// nilai atribut selalu ditulis dalam kutip ganda; '&' dibiarkan karena
// konten lama sudah berisi entity (mis. "&amp;" di URL)
function EscapeAttr(const AValue: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(AValue) do
    case AValue[i] of
      '"': Result := Result + '&quot;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '[': Result := Result + '&#91;';
      ']': Result := Result + '&#93;';
      '`': Result := Result + '&#96;';
    else
      Result := Result + AValue[i];
    end;
end;

// decode entity numerik & beberapa entity bernama, cukup untuk memeriksa
// skema URL (mis. "jav&#x61;script:" / "javascript&colon;")
function DecodeForCheck(const AValue: string): string;
var
  i, j, code: integer;
  ent: string;
begin
  Result := '';
  i := 1;
  while i <= Length(AValue) do
  begin
    if AValue[i] = '&' then
    begin
      j := i + 1;
      while (j <= Length(AValue)) and (j - i < 12) and
        (AValue[j] in ['a'..'z', 'A'..'Z', '0'..'9', '#']) do
        Inc(j);
      ent := LowerCase(Copy(AValue, i + 1, j - i - 1));
      code := -1;
      if (Length(ent) > 1) and (ent[1] = '#') then
      begin
        if (Length(ent) > 2) and (ent[2] = 'x') then
          code := StrToIntDef('$' + Copy(ent, 3, 8), -1)
        else
          code := StrToIntDef(Copy(ent, 2, 8), -1);
      end
      else if ent = 'colon' then code := Ord(':')
      else if ent = 'tab' then code := 9
      else if ent = 'newline' then code := 10
      else if ent = 'amp' then code := Ord('&');
      if (code >= 0) and (code < 128) then
      begin
        Result := Result + Chr(code);
        i := j;
        if (i <= Length(AValue)) and (AValue[i] = ';') then
          Inc(i);
        Continue;
      end;
    end;
    Result := Result + AValue[i];
    Inc(i);
  end;
end;

function IsSafeURL(const AURL: string): boolean;
var
  decoded, s, scheme: string;
  i, p: integer;
begin
  // buang whitespace & karakter kontrol (browser mengabaikannya di skema)
  decoded := DecodeForCheck(AURL);
  s := '';
  for i := 1 to Length(decoded) do
    if decoded[i] > ' ' then
      s := s + decoded[i];
  s := LowerCase(s);
  Result := True;
  p := Pos(':', s);
  if p = 0 then
    Exit; // URL relatif
  // ':' setelah '/', '?' atau '#' bukan skema (mis. "/a?b=c:d")
  for i := 1 to p - 1 do
    if s[i] in ['/', '?', '#'] then
      Exit;
  scheme := Copy(s, 1, p - 1);
  Result := (scheme = 'http') or (scheme = 'https') or (scheme = 'mailto')
    or (scheme = 'ftp');
end;

function IsSafeStyle(const AValue: string): boolean;
var
  s: string;
begin
  s := LowerCase(DecodeForCheck(AValue));
  s := DelChars(DelChars(DelChars(s, ' '), #9), '\');
  Result := (Pos('expression', s) = 0) and (Pos('url(', s) = 0) and
    (Pos('javascript', s) = 0) and (Pos('@import', s) = 0) and
    (Pos('behavior', s) = 0) and (Pos('-moz-binding', s) = 0) and
    (Pos('position:fixed', s) = 0) and (Pos('position:absolute', s) = 0);
end;

type
  TParsedTag = record
    Name: string;
    IsClosing: boolean;
    Attrs: string;   // atribut yang sudah disaring, diawali spasi
    EndPos: integer; // posisi '>'
  end;

// parse tag yang dimulai di AStart ('<'); False bila bukan tag valid
function ParseTag(const S: string; AStart: integer; out ATag: TParsedTag): boolean;
var
  i, n, nameStart: integer;
  attrName, attrValue: string;
  quote: char;
  hasValue: boolean;
begin
  Result := False;
  ATag.Name := '';
  ATag.IsClosing := False;
  ATag.Attrs := '';
  ATag.EndPos := 0;
  n := Length(S);
  i := AStart + 1;
  if (i <= n) and (S[i] = '/') then
  begin
    ATag.IsClosing := True;
    Inc(i);
  end;
  if (i > n) or not (S[i] in ['a'..'z', 'A'..'Z']) then
    Exit;
  nameStart := i;
  while (i <= n) and (S[i] in ['a'..'z', 'A'..'Z', '0'..'9']) do
    Inc(i);
  ATag.Name := LowerCase(Copy(S, nameStart, i - nameStart));
  // setelah nama harus whitespace, '/' atau '>'
  if (i <= n) and not (S[i] in [' ', #9, #10, #13, #12, '/', '>']) then
    Exit;

  // atribut
  while i <= n do
  begin
    while (i <= n) and (S[i] in [' ', #9, #10, #13, #12, '/']) do
      Inc(i);
    if i > n then
      Exit; // tidak ada '>'
    if S[i] = '>' then
    begin
      ATag.EndPos := i;
      Exit(True);
    end;
    nameStart := i;
    while (i <= n) and not (S[i] in [' ', #9, #10, #13, #12, '/', '>', '=']) do
      Inc(i);
    attrName := LowerCase(Copy(S, nameStart, i - nameStart));
    while (i <= n) and (S[i] in [' ', #9, #10, #13, #12]) do
      Inc(i);
    attrValue := '';
    hasValue := False;
    if (i <= n) and (S[i] = '=') then
    begin
      hasValue := True;
      Inc(i);
      while (i <= n) and (S[i] in [' ', #9, #10, #13, #12]) do
        Inc(i);
      if (i <= n) and (S[i] in ['"', '''']) then
      begin
        quote := S[i];
        Inc(i);
        nameStart := i;
        while (i <= n) and (S[i] <> quote) do
          Inc(i);
        if i > n then
          Exit; // kutip tidak ditutup
        attrValue := Copy(S, nameStart, i - nameStart);
        Inc(i);
      end
      else
      begin
        nameStart := i;
        while (i <= n) and not (S[i] in [' ', #9, #10, #13, #12, '>']) do
          Inc(i);
        attrValue := Copy(S, nameStart, i - nameStart);
      end;
    end;

    if ATag.IsClosing or (attrName = '') then
      Continue;
    if not InList(attrName, ALLOWED_ATTRS) then
      Continue;
    if InList(attrName, URL_ATTRS) then
    begin
      if (not hasValue) or (not IsSafeURL(attrValue)) then
        Continue;
      if (attrName = 'src') and (ATag.Name <> 'img') then
        Continue;
      if (attrName = 'href') and (ATag.Name <> 'a') then
        Continue;
    end;
    if (attrName = 'style') and not IsSafeStyle(attrValue) then
      Continue;
    if attrName = 'target' then
    begin
      if ATag.Name <> 'a' then
        Continue;
      attrValue := '_blank';
    end;
    ATag.Attrs := ATag.Attrs + ' ' + attrName + '="' + EscapeAttr(attrValue) + '"';
  end;
end;

// posisi setelah '</name ... >' (case-insensitive), atau setelah akhir string
function SkipToClosingTag(const S, AName: string; AFrom: integer): integer;
var
  p, q: integer;
  lower: string;
begin
  lower := LowerCase(S);
  p := PosEx('</' + AName, lower, AFrom);
  if p = 0 then
    Exit(Length(S) + 1);
  q := PosEx('>', S, p);
  if q = 0 then
    Exit(Length(S) + 1);
  Result := q + 1;
end;

function SafeHTML(const AHTML: string): string;
var
  i, n, p: integer;
  tag: TParsedTag;
  sb: TStringBuilder;
begin
  n := Length(AHTML);
  sb := TStringBuilder.Create(n + 64);
  try
    i := 1;
    while i <= n do
    begin
      case AHTML[i] of
        '<':
        begin
          // komentar / CDATA / doctype dibuang
          if Copy(AHTML, i, 4) = '<!--' then
          begin
            p := PosEx('-->', AHTML, i + 4);
            if p = 0 then
              i := n + 1
            else
              i := p + 3;
            Continue;
          end;
          if (i < n) and (AHTML[i + 1] in ['!', '?']) then
          begin
            p := PosEx('>', AHTML, i);
            if p = 0 then
              i := n + 1
            else
              i := p + 1;
            Continue;
          end;

          if not ParseTag(AHTML, i, tag) then
          begin
            sb.Append('&lt;');
            Inc(i);
            Continue;
          end;

          if InList(tag.Name, DROP_CONTENT_TAGS) then
          begin
            if tag.IsClosing then
              i := tag.EndPos + 1
            else
              i := SkipToClosingTag(AHTML, tag.Name, tag.EndPos + 1);
            Continue;
          end;

          if IsAllowedTag(tag.Name) then
          begin
            if tag.IsClosing then
            begin
              if not InList(tag.Name, VOID_TAGS) then
                sb.Append('</' + tag.Name + '>');
            end
            else
            begin
              if (tag.Name = 'a') and (Pos(' href="', tag.Attrs) > 0) then
                tag.Attrs := tag.Attrs + ' rel="nofollow noopener"';
              if InList(tag.Name, VOID_TAGS) then
                sb.Append('<' + tag.Name + tag.Attrs + ' />')
              else
                sb.Append('<' + tag.Name + tag.Attrs + '>');
            end;
          end;
          // tag lain: dibuang, isinya tetap
          i := tag.EndPos + 1;
        end;
        '>': begin sb.Append('&gt;'); Inc(i); end;
        '[': begin sb.Append('&#91;'); Inc(i); end;
        ']': begin sb.Append('&#93;'); Inc(i); end;
      else
        begin
          sb.Append(AHTML[i]);
          Inc(i);
        end;
      end;
    end;
    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

end.
