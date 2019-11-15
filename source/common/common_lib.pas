unit common_lib;

{$mode objfpc}{$H+}

interface

uses
  fpcgi,
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

function SetOpenGraph(ATitle, AImage, AURL: string): boolean;
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

function GetOpenGraphImage(AContent: string; ADefault: string): string;
begin
  Result := ADefault;
  try
    with TRegExpr.Create do
    begin
      Expression := '<img src="(.+?)"';
      if Exec(AContent) then
      begin
        Result := Match[1];
        Result := Result.Replace('"', '').Replace('''', '').Trim;
        Result := Result.Replace('http://', 'https://');
      end;
      Free;
    end;
  except
  end;
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

function SetOpenGraph(ATitle, AImage, AURL: string): boolean;
begin
  ThemeUtil.AddMeta('og:type', 'website', 'property');
  ThemeUtil.AddMeta('og:title', ATitle, 'property');
  ThemeUtil.AddMeta('og:image', AImage, 'property');
  ThemeUtil.AddMeta('og:site_name', Config['systems/sitename'], 'property');
  ThemeUtil.AddMeta('og:url', AURL, 'property');
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
  if not UserSession.IsExpired then
    ThemeUtil.Assign('__is_logged_in__', '0')
  else
    ThemeUtil.Assign('__is_logged_in__', '1');

  //_SESSION['uid'] := UserSession.UserId; // move -> facebook login handler
  ThemeUtil.Assign('__username__', UserSession.UserName);
  ThemeUtil.Assign('__gravatar__', UserSession.Gravatar);
  ThemeUtil.Assign('__ipaddress__', UserSession.IPAddress);
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

