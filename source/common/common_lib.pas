unit common_lib;

{$mode objfpc}{$H+}

interface

uses
  fastplaz_app,
  fastplaz_handler, html_lib, theme_controller, RegExpr,
  Classes, SysUtils, dateutils, string_helpers;

{$include ../common/common.inc}

type
  TUserSession = record
    IsExpired: boolean;
    Token: string;
    UserId: integer;
    UserName: string;
    Gravatar: string;
    IPAddress: string;
    ExpiredDate: TDateTime;
  end;

var
  Lang: string;
  Page: integer;

function GetLang: string;
function GetPage: integer;
function GenerateSlug(AText: string): string;
function GeneratePagination(ACurrentPage: integer; ANumberOfPage: integer;
  ABaseURL: string = '?page='): string;
function GetOpenGraphImage(AContent: string; ADefault: string = 'logo.png'): string;
function ReplaceFromLegacy(AContent: string): string;

function GetOpenGraphDescription(AContent: string; AMaxLength: integer = 200): string;
function SetOpenGraph(ATitle, AImage, AURL: string; ADescription: string = '';
  AType: string = 'website'; ALargeImage: boolean = False): boolean;
function GetUserSessionInfo: boolean;
procedure SetThemeParameter;
procedure ResetSession;

var
  GoogleToken, FacebookToken: string;
  UserSession: TUserSession;

implementation

uses common;

function GetLang: string;
begin
  Result := _GET['lang'];
  if Result.IsEmpty then
    Result := Config['systems/language_default'];
end;

function GetPage: integer;
begin
  Result := _GET['page'].AsInteger;
  if Result = 0 then
    Result := 1;
end;

function GenerateSlug(AText: string): string;
begin
  Result := HTMLUtil.Permalink(AText);
end;

function GeneratePagination(ACurrentPage: integer; ANumberOfPage: integer;
  ABaseURL: string): string;
var
  i, firstPage, lastPage: integer;
begin
  { Previous
  Result := '<li class="active">Prev</li>';
  if ACurrentPage > 1 then
    Result := '<li class="active"><a href="'+ABaseURL+i2s(ACurrentPage-1)+'">Prev</a></li>';
  }
  Result := '';
  if ANumberOfPage > 3 then
  begin
    Result := '<li class="active">First</li>';
    if ACurrentPage > 1 then
      Result := '<li class="active"><a href="' + ABaseURL + i2s(1) + '">First</a></li>';
  end;

  firstPage := ACurrentPage - 3;
  if firstPage <= 1 then
    firstPage := 1
  else
    Result += '<li>...</li>';
  lastPage := ACurrentPage + 3;
  if lastPage >= ANumberOfPage then
    lastPage := ANumberOfPage;
  for i := firstPage to lastPage do
  begin
    if i = ACurrentPage then
      Result := Result + #10'<li class="active">' + i.ToString + '</li>'
    else
      Result := Result + #10'<li class="active"><a href="' + ABaseURL +
        i.ToString + '">' + i.ToString + '</a></li>';
  end;

  if lastPage < ANumberOfPage then
    Result += '<li>...</li>';
  if ANumberOfPage > 3 then
  begin
    if ACurrentPage = ANumberOfPage then
      Result := Result + #10'<li class="active">Last</li>'
    else
      Result := Result + #10'<li class="active"><a href="' + ABaseURL +
        i2s(ANumberOfPage) + '">Last</a></li>';
  end;
end;

// first <img> in the content as an absolute URL (Open Graph needs one)
function GetOpenGraphImage(AContent: string; ADefault: string): string;
var
  url, base: string;
begin
  Result := ADefault;
  try
    with TRegExpr.Create do
    try
      ModifierI := True;
      // src can be anywhere in the tag, quoted with " or ' or unquoted
      Expression := '<img\s[^>]*?\bsrc\s*=\s*["'']?([^"''\s>]+)';
      if Exec(AContent) then
      begin
        url := Trim(Match[1]);
        if url = '' then
          Exit;
        if Copy(url, 1, 5) = 'data:' then
          Exit;
        base := ThemeUtil.BaseURL;
        if (base <> '') and (base[Length(base)] = '/') then
          Delete(base, Length(base), 1);
        if Copy(url, 1, 2) = '//' then
          url := 'https:' + url
        else if Copy(url, 1, 7) = 'http://' then
          url := 'https://' + Copy(url, 8, MaxInt)
        else if Copy(url, 1, 8) <> 'https://' then
        begin
          // relative path
          if Copy(url, 1, 1) <> '/' then
            url := '/' + url;
          url := base + url;
        end;
        Result := url;
      end;
    finally
      Free;
    end;
  except
  end;
end;

// plain text summary of HTML content for meta description
function GetOpenGraphDescription(AContent: string; AMaxLength: integer): string;
var
  i: integer;
begin
  Result := ReplaceRegExpr('(?i)<(br|/p|/li|/h[1-6]|/div)[^>]*>', AContent, ' ', False);
  Result := html_lib.StripTags(Result);
  Result := StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&#39;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
  Result := Trim(ReplaceRegExpr('\s+', Result, ' ', False));
  if Length(Result) <= AMaxLength then
    Exit;
  // cut at a word boundary, and not in the middle of a UTF-8 character
  i := AMaxLength;
  while (i > AMaxLength div 2) and (Result[i] <> ' ') do
    Dec(i);
  if Result[i] <> ' ' then
  begin
    i := AMaxLength;
    while (i > 1) and ((Ord(Result[i + 1]) and $C0) = $80) do
      Dec(i);
  end;
  Result := TrimRight(Copy(Result, 1, i)) + '...';
end;

function ReplaceFromLegacy(AContent: string): string;
begin
  Result := AContent.Replace('href="http://delphi-id.org/',
    'href="' + ThemeUtil.BaseURL + 'legacy/delphi-id.org/');
  Result := Result.Replace('href=http://delphi-id.org/',
    'href=' + ThemeUtil.BaseURL + 'legacy/delphi-id.org/');
  Result := Result.Replace('src=http://delphi-id.org/',
    'src=' + ThemeUtil.BaseURL + 'legacy-image/delphi-id.org/');
  Result := Result.Replace('src="http://delphi-id.org/',
    'src="' + ThemeUtil.BaseURL + 'legacy-image/delphi-id.org/');
  Result := Result.Replace('http://delphi-id.org/syntax',
    'https://pascal-id.org/syntax');
end;

// AddMeta writes the content as-is, so every value is HTML-encoded here
function SetOpenGraph(ATitle, AImage, AURL: string; ADescription: string;
  AType: string; ALargeImage: boolean): boolean;
var
  title, image, url, description: string;
begin
  title := HTMLEncode(ATitle);
  image := HTMLEncode(AImage);
  url := HTMLEncode(AURL);
  description := HTMLEncode(ADescription);

  ThemeUtil.AddMeta('og:type', AType, 'property');
  ThemeUtil.AddMeta('og:title', title, 'property');
  if description <> '' then
    ThemeUtil.AddMeta('og:description', description, 'property');
  ThemeUtil.AddMeta('og:image', image, 'property');
  ThemeUtil.AddMeta('og:site_name', HTMLEncode(Config['systems/sitename']), 'property');
  ThemeUtil.AddMeta('og:url', url, 'property');
  if description <> '' then
    ThemeUtil.AddMeta('description', description);

  //twitter
  if ALargeImage then
    ThemeUtil.AddMeta('twitter:card', 'summary_large_image')
  else
    ThemeUtil.AddMeta('twitter:card', 'summary');
  ThemeUtil.AddMeta('twitter:title', title);
  if description <> '' then
    ThemeUtil.AddMeta('twitter:description', description);
  ThemeUtil.AddMeta('twitter:image', image);
  ThemeUtil.AddMeta('twitter:url', url);

  Result := True;
end;

function GetUserSessionInfo: boolean;
var
  ts: int64;
begin
  ts := s2i(_SESSION['token_expired_timestamp']);
  UserSession.Token := _SESSION['token'];
  UserSession.UserId := s2i(_SESSION['user_id']);
  UserSession.UserName := _SESSION['user_name'];
  UserSession.Gravatar := _SESSION['gravatar'];
  UserSession.Token := _SESSION['token'];
  UserSession.ExpiredDate := UnixToDateTime(ts);
  UserSession.IPAddress := Application.Request.RemoteAddress;

  UserSession.IsExpired := False;
  if UserSession.ExpiredDate < Now then
  begin
    UserSession.IsExpired := True;
  end;

  Result := not UserSession.IsExpired;
end;

procedure SetThemeParameter;
begin
  ThemeUtil.Assign(TAG_USER_CAN_EDIT, '1');
  if not UserSession.IsExpired then
    ThemeUtil.Assign(TAG_IS_LOGGED_IN, '0')
  else
    ThemeUtil.Assign(TAG_IS_LOGGED_IN, '1');

  //_SESSION['uid'] := UserSession.UserId; // move -> facebook login handler
  ThemeUtil.Assign(TAG_USERNAME, UserSession.UserName);
  ThemeUtil.Assign(TAG_GRAVATAR, UserSession.Gravatar);
  ThemeUtil.Assign(TAG_IP_ADDRESS, UserSession.IPAddress);
end;

procedure ResetSession;
begin
  SessionController.EndSession();
  {
  _SESSION['token'] := '';
  _SESSION['user_id'] := 0;
  _SESSION['user_name'] := '';
  _SESSION['gravatar'] := '';
  _SESSION['token_expired'] := '';
  _SESSION['token_expired_timestamp'] := 0;
  }
end;

initialization
  Page := 1;
  Lang := LANGUAGE_DEFAULT;

end.

