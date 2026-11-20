unit facebook_lib;

{
  Verifikasi Facebook access token di sisi server.

  Token dari browser TIDAK boleh dipercaya begitu saja: identitas user
  (id, nama, email) harus diambil dari Graph API memakai token tersebut,
  dan token harus milik aplikasi Facebook situs ini (bukan aplikasi lain).

  USAGE:
    if not IsValidTokenFormat(token) then ... // tolak
    if FacebookVerifyToken(token, profile) then
      // profile.Id, profile.Email, ... berasal dari Facebook
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, fastplaz_handler, http_lib, json_lib;

type
  TFacebookProfile = record
    Id: string;
    FirstName: string;
    LastName: string;
    Email: string;
  end;

function IsValidTokenFormat(const AToken: string): boolean;
function IsNumericId(const AValue: string): boolean;
function FacebookVerifyToken(const AToken: string;
  out AProfile: TFacebookProfile): boolean;

implementation

uses common;

{$include common.inc}

const
  GRAPH_URL = 'https://graph.facebook.com/';
  GRAPH_TIMEOUT = 5000;

// access token Facebook hanya berisi huruf/angka (umumnya "EAA..."),
// karakter lain (kutip, spasi, dll) langsung ditolak
function IsValidTokenFormat(const AToken: string): boolean;
var
  i: integer;
begin
  Result := False;
  if (Length(AToken) < 20) or (Length(AToken) > 1024) then
    Exit;
  for i := 1 to Length(AToken) do
    if not (AToken[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '-', '.']) then
      Exit;
  Result := True;
end;

function IsNumericId(const AValue: string): boolean;
var
  i: integer;
begin
  Result := False;
  if (AValue = '') or (Length(AValue) > 20) then
    Exit;
  for i := 1 to Length(AValue) do
    if not (AValue[i] in ['0'..'9']) then
      Exit;
  Result := True;
end;

function GraphGet(const APath, AToken: string; AJson: TJSONUtil): boolean;
var
  response: IHTTPResponse;
  sep: string;
begin
  Result := False;
  sep := '?';
  if Pos('?', APath) > 0 then
    sep := '&';
  try
    with THTTPLib.Create do
    try
      ConnectTimeout := GRAPH_TIMEOUT;
      IOTimeout := GRAPH_TIMEOUT;
      URL := GRAPH_URL + APath + sep + 'access_token=' + UrlEncode(AToken);
      response := Get();
      if response.ResultCode <> 200 then
        Exit;
      Result := AJson.LoadFromJsonString(response.ResultText);
    finally
      Free;
    end;
  except
    Result := False;
  end;
end;

function AppId: string;
begin
  Result := Trim(Config.GetString('facebook/app_id'));
  if Result = '' then
    Result := FACEBOOK_APP_ID;
end;

function FacebookVerifyToken(const AToken: string;
  out AProfile: TFacebookProfile): boolean;
var
  json: TJSONUtil;
begin
  Result := False;
  AProfile.Id := '';
  AProfile.FirstName := '';
  AProfile.LastName := '';
  AProfile.Email := '';
  if not IsValidTokenFormat(AToken) then
    Exit;

  json := TJSONUtil.Create;
  try
    // 1. token harus milik aplikasi situs ini
    if not GraphGet('app', AToken, json) then
      Exit;
    if VarToStr(json['id']) <> AppId then
      Exit;

    // 2. identitas user diambil dari Facebook, bukan dari request
    json.Clear;
    if not GraphGet('me?fields=id,first_name,last_name,email', AToken, json) then
      Exit;
    AProfile.Id := VarToStr(json['id']);
    AProfile.FirstName := VarToStr(json['first_name']);
    AProfile.LastName := VarToStr(json['last_name']);
    AProfile.Email := Trim(VarToStr(json['email']));
    if not IsNumericId(AProfile.Id) then
      Exit;

    Result := True;
  finally
    json.Free;
  end;
end;

end.
