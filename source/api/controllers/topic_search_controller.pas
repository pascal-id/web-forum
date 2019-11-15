unit topic_search_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler, 
    database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TTopicSearchController = class(TMyCustomController)
  private
    json : TJSONUtil;
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Options; override;
  end;

implementation

uses common, topic_model;

constructor TTopicSearchController.CreateNew(AOwner: TComponent;
  CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  json := TJSONUtil.Create;
end;

destructor TTopicSearchController.Destroy;
begin
  json.Free;
  inherited Destroy;
end;

// GET Method Handler
procedure TTopicSearchController.Get;
var
  keyword: string;
  topicAsArray: TJSONArray;
begin
  keyword := _GET['q'];
  if keyword.IsEmpty then
    OutputJson(404, ERR_INVALID_PARAMETER);

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  json['code'] := 0;

  with TTopicModel.Create() do
  begin
    if not SearchTitle(keyword, NEWS_DEFAULT_LIMIT) then
    begin
      json['code'] := 404;
      json['msg'] := ERR_DATA_NOT_FOUND;
    end
    else
    begin
      topicAsArray := AsJsonArray(False);
      json['code'] := 0;
      json['count'] := topicAsArray.Count;
      json.ValueArray['data'] := topicAsArray;
    end;
    Free;
  end;

  // Respose
  Response.ContentType := 'application/json';
  Response.Content := json.AsJSON;
end;

// POST Method Handler
procedure TTopicSearchController.Post;
begin
  Response.Content := '{}';
end;

// OPTIONS Method Handler
procedure TTopicSearchController.Options;
begin
  Response.Code := 204;
  Response.Content := '';
end;


end.

