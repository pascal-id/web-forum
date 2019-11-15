unit auth_facebook_controller;
{
  USAGE:

  [x] Is Token Valid
  curl "http://www.pascal-id.test/api/auth/facebook/"  -H 'token:[token]'

  [x] Facebook Login
  curl -X POST "http://www.pascal-id.test/api/auth/facebook/" \
    -H 'token:[token]' \
    -d '{"first_name":"Luri","last_name":"Darmawan","email":"luri@kioss.com","name":"Luri Darmawan","id":"10218042891638356"}'

}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TAuthFacebookController = class(TMyCustomController)
  private
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Options; override;
  end;

implementation

uses common, auth_user_model, auth_token_model, user_model, common_lib;

constructor TAuthFacebookController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
end;

destructor TAuthFacebookController.Destroy;
begin
  inherited Destroy;
end;

// GET Method Handler
procedure TAuthFacebookController.Get;
var
  json: TJSONUtil;
  tokenElapsed: Integer;
begin
  FacebookToken := GetEnvironmentVariable('Token');
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
      json['user_id'] := Value['user_id'];
      json['elapsed_time'] := tokenElapsed;
    end;
    Free;
  end;

  Response.ContentType := 'application/json';
  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
procedure TAuthFacebookController.Post;
begin
  //TODO: api to handle facebook login
end;

// OPTIONS Method Handler
procedure TAuthFacebookController.Options;
begin
  Response.Code := 204;
  Response.Content := '';
end;

end.

