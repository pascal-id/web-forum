unit news_search_controller;

{
  USAGE:

  [x] News Search
  curl "http://www.pascal-id.test/api/news/search/?q=keyword"

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TNewsSearchController = class(TMyCustomController)
  private
    json: TJSONUtil;
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Options; override;
  end;

implementation

uses common, news_model;

constructor TNewsSearchController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  json := TJSONUtil.Create;
end;

destructor TNewsSearchController.Destroy;
begin
  json.Free;
  inherited Destroy;
end;

// GET Method Handler
procedure TNewsSearchController.Get;
var
  keyword: string;
  newsAsArray: TJSONArray;
begin
  keyword := _GET['q'];
  if keyword.IsEmpty then
    OutputJson(404, ERR_INVALID_PARAMETER);

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  json['code'] := 0;
  json['search'] := keyword;

  with TNewsModel.Create() do
  begin
    if not SearchTitle(keyword, NEWS_DEFAULT_LIMIT) then
    begin
      json['code'] := 404;
      json['msg'] := ERR_DATA_NOT_FOUND;
    end
    else
    begin
      newsAsArray := AsJsonArray(False);
      json['code'] := 0;
      json['count'] := newsAsArray.Count;
      json.ValueArray['data'] := newsAsArray;
    end;
    Free;
  end;

  // Respose
  Response.ContentType := 'application/json';
  Response.Content := json.AsJSON;
end;

// POST Method Handler
procedure TNewsSearchController.Post;
begin
  Response.Content := '{}';
end;

// OPTIONS Method Handler
procedure TNewsSearchController.Options;
begin
  Response.Code := 204;
  Response.Content := '';
end;

end.



