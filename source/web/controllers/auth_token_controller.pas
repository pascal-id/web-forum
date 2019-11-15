unit auth_token_controller;
{
  USAGE:

  [x] Is Token Valid
  curl "http://www.pascal-id.test/auth/token/"  -H 'Token:[token]'

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TAuthTokenController = class(TMyCustomController)
  private
    function Tag_MainContent_Handler(const TagName: string; Params: TStringList
      ): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common, common_lib, auth_token_model;

constructor TAuthTokenController.CreateNew(AOwner: TComponent;
  CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TAuthTokenController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TAuthTokenController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TAuthTokenController.Get;
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
      _SESSION['retest'] := 123;
      }

    end;
    Free;
  end;

  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
procedure TAuthTokenController.Post;
begin
end;

function TAuthTokenController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
end;

end.

