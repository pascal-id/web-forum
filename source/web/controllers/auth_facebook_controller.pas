unit auth_facebook_controller;
{
  USAGE:

  [x] Is Token Valid
  curl "http://www.pascal-id.test/auth/facebook/"  -H 'Token:[token]'

  [x] Facebook Login
  curl -X POST "http://www.pascal-id.test/auth/facebook/" \
    -H 'Token:[token]'

  Token diverifikasi ke Graph API (lihat common/facebook_lib.pas);
  id/nama/email diambil dari Facebook, request body tidak dipakai.

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fastplaz_app, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TAuthFacebookController = class(TMyCustomController)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common, common_lib, auth_token_model, auth_user_model,
  user_model, facebook_lib;

constructor TAuthFacebookController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TAuthFacebookController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TAuthFacebookController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TAuthFacebookController.Get;
var
  json: TJSONUtil;
  tokenElapsed: integer;
begin
  FacebookToken := Header['Token'];
  if not IsValidTokenFormat(FacebookToken) then
  begin
    OutputJson(400, ERR_AUTH_INVALID_TOKEN);
    Exit;
  end;

  DataBaseInit();

  json := TJSONUtil.Create;
  json['code'] := 404;
  with TAuthTokenModel.Create() do
  begin
    if IsValid(FacebookToken) then
    begin
      tokenElapsed := SecondsBetween(Now, ExpiredDate);
      json['code'] := 0;
      json['token'] := Value['token'];
      json['elapsed_time'] := tokenElapsed;

      // repost session
      {
      _SESSION['token'] := FacebookToken;
      _SESSION['user_id'] := Value['user_id'];
      _SESSION['uid'] := Value['user_id']; // compatibility
      _SESSION['user_name'] := Value['username'];
      _SESSION['gravatar'] := Value['gravatar'];
      _SESSION['token_expired'] := ExpiredDate;
      _SESSION['token_expired_timestamp'] := DateTimeToUnix( ExpiredDate);
      }

    end;
    Free;
  end;

  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
// Identitas user (id, nama, email) diambil dari Graph API memakai token,
// BUKAN dari request body; body dari browser diabaikan.
procedure TAuthFacebookController.Post;
var
  userName, userGravatar: String;
  userId: integer;
  json: TJSONUtil;
  profile: TFacebookProfile;
begin
  FacebookToken := Header['Token'];
  if not IsValidTokenFormat(FacebookToken) then
  begin
    OutputJson(400, ERR_AUTH_INVALID_TOKEN);
    Exit;
  end;

  if not FacebookVerifyToken(FacebookToken, profile) then
  begin
    OutputJson(401, ERR_AUTH_INVALID_TOKEN);
    Exit;
  end;

  if profile.Email = '' then
  begin
    OutputJson(400, ERR_AUTH_EMAIL_REQUIRED);
    Exit;
  end;

  DataBaseInit();
  userId := 0;
  userName := '';
  userGravatar := '';
  with TAuthUserModel.Create() do
  begin
    if FindByEmail(profile.Email) then
    begin
      userId := Value['auid'];
      userName := Value['username'];
      userGravatar := Value['gravatar'];
      if not isMappingExist(userId, profile.Id) then
      begin
        with TUserModel.Create() do
        begin
          AddMapping(1, userId, profile.Id, profile.Email);
          Free;
        end;
      end;
    end
    else
    begin
      // Add User From Facebook Data
      with TUserModel.Create() do
      begin
        if AddFromFacebook(StrToInt64(profile.Id), profile.FirstName,
          profile.LastName, profile.Email) then
        begin
          userId := NewUserId;
          userName := CurrentUserName;
        end;
        Free;
      end;
    end;

    Free;
  end;

  if userId <= 0 then
  begin
    OutputJson(400, ERR_UNKNOWN);
    Exit;
  end;

  // simpan token ke DB
  json := TJSONUtil.Create;
  json['code'] := 400;
  with TAuthTokenModel.Create() do
  begin
    if AddToken(FacebookToken, userId) then
    begin
      json['code'] := 0;
      json['token'] := FacebookToken;
      json['user_id'] := userId;
      json['user_name'] := userName;
      json['elapsed_time'] := SecondsBetween(Now, ExpiredDate);

      _SESSION['token'] := FacebookToken;
      _SESSION['user_id'] := userId;
      _SESSION['uid'] := userId; // compatibility
      _SESSION['user_name'] := userName;
      _SESSION['gravatar'] := userGravatar;
      _SESSION['token_expired'] := ExpiredDate;
      _SESSION['token_expired_timestamp'] := DateTimeToUnix( ExpiredDate);

    end;
    Free;
  end;

  Response.ContentType := 'application/json';
  Response.Content := json.AsJSON;
  json.Free;
end;


end.
