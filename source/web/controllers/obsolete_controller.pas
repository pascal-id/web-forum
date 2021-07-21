unit obsolete_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TObsoleteController }

  TObsoleteController = class(TMyCustomController)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common, common_lib, obsolete_model;

constructor TObsoleteController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TObsoleteController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TObsoleteController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TObsoleteController.Get;
begin
  Response.Content := '{obsolete}';
end;

// POST Method Handler
procedure TObsoleteController.Post;
var
  moduleName, description : string;
  referenceId: integer;

begin
  if not GetUserSessionInfo then
    OutputJson(400, ERR_NOT_PERMITTED);

  moduleName := _POST['module'];
  referenceId := _POST['id'].ToInteger;
  description := UrlDecode(_POST['description']);
  description := description.Replace('\n',#10);
  if moduleName.IsEmpty then
    OutputJson(400, ERR_INVALID_PARAMETER);
  if referenceId = 0 then
    OutputJson(400, ERR_INVALID_PARAMETER);

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  with TObsoleteModel.Create() do
  begin
    Value['date'] := Now.AsString;
    Value['module'] := moduleName;
    Value['user_id'] := UserSession.UserId;
    Value['ref_id'] := referenceId;
    Value['title'] := _POST['title'];
    Value['description'] := description;
    Value['status_id'] := 2;
    Save;
    Free;
  end;

  OutputJson(200, OK);
end;


end.





