unit thread_controller;

{
  USAGE:

  [x] Get Topic/Thread History
  curl "http://www.pascal-id.test/api/topic/thread/{topicId}/{slug}/"

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TThreadModule }

  TThreadModule = class(TMyCustomWebModule)
  private
    FTopicID: integer;
    FLimit: integer;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Options; override;
  end;

implementation

uses common, topic_model;

procedure TThreadModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

constructor TThreadModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TThreadModule.Destroy;
begin
  inherited Destroy;
end;

// GET Method Handler
procedure TThreadModule.Get;
var
  pageIndex: Integer;
  topicAsArray: TJSONArray;
  json: TJSONUtil;
begin
  json := TJSONUtil.Create;
  json['code'] := 404;

  FTopicID := _GET['$1'].AsInteger;
  FLimit := _GET['limit'].AsInteger;
  pageIndex := _GET['page'].AsInteger;
  if pageIndex = 0 then
    pageIndex := 1;
  if FLimit = 0 then
    FLimit := THREAD_DEFAULT_LIMIT;

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  with TTopicModel.Create() do
  begin
    topicAsArray := Thread(FTopicID, pageIndex, FLimit);
    if topicAsArray.Count > 0 then
    begin
      json['code'] := 0;
      json['count'] := topicAsArray.Count;
      json['info/thread_title'] := ThreadTitle;
      json['info/replies'] := NumberOfReplies;
      json['info/page'] := CurrentPage;
      json['info/cat_id'] := CategoryId;
      json['info/cat_name'] := CategoryTitle;
      json['info/forum_id'] := ForumId;
      json['info/forum_name'] := ForumTitle;
      json.ValueArray['data'] := topicAsArray;
    end else
    begin
      json['code'] := 404;
      json['msg'] := ERR_DATA_NOT_FOUND;
    end;
    Free;
  end;

  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
procedure TThreadModule.Post;
begin
  Response.Content := '';
end;

// OPTIONS Method Handler
procedure TThreadModule.Options;
begin
  Response.Code := 204;
  Response.Content := '';
end;


initialization

end.

