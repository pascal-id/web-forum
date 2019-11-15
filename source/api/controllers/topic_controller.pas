unit topic_controller;

{
  USAGE:

  [x] Get Topik List
  curl "http://www.pascal-id.test/api/topic/recent/?limit=2"

}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TTopicModule }

  TTopicModule = class(TMyCustomWebModule)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    json: TJSONUtil;
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Options; override;
  end;

  { TTopicRecentModule }

  TTopicRecentModule = class(TTopicModule)
  public
    procedure Get; override;
  end;

  { TTopicLastModule }

  TTopicLastModule = class(TTopicModule)
  public
    procedure Get; override;
  end;

implementation

uses common, topic_model;

constructor TTopicModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  json := TJSONUtil.Create;
end;

destructor TTopicModule.Destroy;
begin
  json.Free;
  inherited Destroy;
end;

// Init First
procedure TTopicModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TTopicModule.Get;
begin
  Response.Content := '{topic}';
end;

// POST Method Handler
procedure TTopicModule.Post;
begin
end;

procedure TTopicModule.Options;
begin
  Response.Code := 204;
  Response.Content := '';
end;


{ TTopicRecentModule }

procedure TTopicRecentModule.Get;
var
  limitView: integer;
begin
  json['code'] := 404;

  limitView := _GET['limit'].AsInteger;
  if limitView = 0 then
    limitView := TOPIC_DEFAULT_LIMIT;

  DataBaseInit();
  with TTopicModel.Create() do
  begin
    json['code'] := 0;
    json['count'] := -1;
    json.ValueArray['data'] := RecentTopic(limitView);
    json['count'] := RecordCount;
    SaveCache('topic_recent', 'satu');
    Free;
  end;

  Response.Content := json.AsJSON;
end;

{ TTopicLastModule }

procedure TTopicLastModule.Get;
var
  limitView: integer;
begin
  json['code'] := 404;

  limitView := _GET['limit'].AsInteger;
  if limitView = 0 then
    limitView := TOPIC_DEFAULT_LIMIT;

  DataBaseInit();
  with TTopicModel.Create() do
  begin
    json['code'] := 0;
    json['count'] := -1;
    json.ValueArray['data'] := LastTopic(limitView);
    json['count'] := RecordCount;
    Free;
  end;

  Response.Content := json.AsJSON;
end;



end.

