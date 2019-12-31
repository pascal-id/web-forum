unit news_controller;
{
  USAGE:

  [x] Get News List


  [x] Get Last News List
  curl "http://www.pascal-id.test/api/news/last/?limit=2"

  [x] News Detail
  curl "http://www.pascal-id.test/api/news/322/lazarus-release-2.0.6"

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TNewsModule = class(TMyCustomWebModule)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    json: TJSONUtil;

    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

  { TNewsLastModule }

  TNewsLastModule = class(TNewsModule)
  public
    procedure Get; override;
  end;

  { TNewsDetailModule }

  TNewsDetailModule = class(TNewsModule)
  public
    procedure Get; override;
  end;



implementation

uses common, news_model;

constructor TNewsModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  json := TJSONUtil.Create;
end;

destructor TNewsModule.Destroy;
begin
  json.Free;
  inherited Destroy;
end;

// Init First
procedure TNewsModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TNewsModule.Get;
begin
  Response.Content := '{news}';
end;

// POST Method Handler
procedure TNewsModule.Post;
begin
end;

{ TNewsLastModule }

procedure TNewsLastModule.Get;
var
  limitParameter: integer;
begin
  limitParameter := _GET['limit'].AsInteger;
  if limitParameter < 2 then
    limitParameter := NEWS_DEFAULT_LIMIT;

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  json['code'] := 0;
  with TNewsModel.Create() do
  begin
    Last(limitParameter, False);
    json['count'] := RecordCount;
    json.ValueArray['data'] := AsJsonArray(False);
    Free;
  end;

  // Respose
  Response.Content := json.AsJSON;
end;

{ TNewsDetailModule }

procedure TNewsDetailModule.Get;
var
  newsIndex: Integer;
  previewOnly: Boolean;
  newsSlug: String;
begin
  newsIndex := _GET['$1'].AsInteger;
  newsSlug := _GET['$2'];

  if newsIndex = 0 then
    OutputJson( 404, ERR_INVALID_PARAMETER);

  previewOnly := False;
  if _GET['preview'] = '1' then
  begin
    previewOnly := True;
    //TODO: check permission to show preview
  end;

  DataBaseInit();
  with TNewsModel.Create() do
  begin
    if not Detail(newsIndex, previewOnly) then
    begin
      json['code'] := 404;
      json['msg'] := ERR_DATA_NOT_FOUND;
    end
    else
    begin
      json['code'] := 0;
      json['count'] := RecordCount;
      json.ValueArray['data'] := AsJsonArray(False);
    end;
    Free;
  end;

  // Respose
  Response.Content := json.AsJSON;
end;


end.

