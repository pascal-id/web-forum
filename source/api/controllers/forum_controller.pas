unit forum_controller;
{
  USAGE:

  [x] Get Forum List
  curl "http://www.pascal-id.test/api/forum/"

}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler, 
    database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TForumModule = class(TMyCustomWebModule)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses common, forum_model;

constructor TForumModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TForumModule.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TForumModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest
  );
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TForumModule.Get;
var
  json: TJSONUtil;
begin
  json := TJSONUtil.Create;
  json['code'] := 404;

  DataBaseInit();
  with TForumModel.Create() do
  begin
    json['code'] := 0;
    json['count'] := -1;
    json.ValueArray['data'] := All;
    die(data.sql);
    json['count'] := RecordCount;
    Free;
  end;

  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
procedure TForumModule.Post;
begin
end;



end.

