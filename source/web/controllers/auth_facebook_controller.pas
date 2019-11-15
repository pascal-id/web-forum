unit auth_facebook_controller;
{
  USAGE:

  [x] Is Token Valid
  curl "http://www.pascal-id.test/auth/facebook/"  -H 'Token:[token]'

  [x] Facebook Login
  curl -X POST "http://www.pascal-id.test/auth/facebook/" \
    -H 'Token:[token]' \
    -d '{"first_name":"Luri","last_name":"Darmawan","email":"luri@kioss.com","name":"Luri Darmawan","id":"10218042891638356"}'

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
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
  user_model;

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
  if FacebookToken.IsEmpty then
    OutputJson(400, ERR_INVALID_PARAMETER);

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');

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
procedure TAuthFacebookController.Post;
var
  tokenElapsedTime: integer;
  facebookId, userName, userGravatar: String;
  userId: integer;
  json, requestAsJson: TJSONUtil;
begin
  FacebookToken := Header['Token'];
  if FacebookToken.IsEmpty then
    OutputJson(400, ERR_INVALID_PARAMETER);
  requestAsJson := TJSONUtil.Create;
  requestAsJson.LoadFromJsonString(Request.Content);

  if requestAsJson['email'] = '' then
  begin
    requestAsJson.Free;
    OutputJson(400, ERR_AUTH_EMAIL_REQUIRED);
  end;

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  json := TJSONUtil.Create;
  json['code'] := 400;
  with TAuthUserModel.Create() do
  begin
    if FindByEmail(requestAsJson['email']) then
    begin
      userId := Value['auid'];
      userName := Value['username'];
      userGravatar := Value['gravatar'];
      facebookId := requestAsJson['id'];
      if not isMappingExist(userId, facebookId) then
      begin
        with TUserModel.Create() do
        begin
          AddMapping(1, userId, facebookId, requestAsJson['email']);
          Free;
        end;
      end;
    end
    else
    begin
      // Add User From Facebook Data
      with TUserModel.Create() do
      begin
        AddFromFacebook(requestAsJson['id'], requestAsJson['first_name'],
          requestAsJson['last_name'], requestAsJson['email']);
        userId := LastInsertID;
        userName := CurrentUserName;
        Free;
      end;
    end;

    Free;
  end;

  // simpan token ke DB
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

