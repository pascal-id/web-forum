unit auth_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler,
  database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TAuthController = class(TMyCustomController)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses common;

constructor TAuthController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TAuthController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TAuthController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TAuthController.Get;
begin
  Response.Content := '{authhh}';
end;

// POST Method Handler
procedure TAuthController.Post;
var
  json: TJSONUtil;
  authstring: string;
begin
  authstring := Header['Authorization'];
  if authstring <> 'YourAuthKey' then
  begin

  end;
  json := TJSONUtil.Create;

  json['code'] := Int16(0);
  json['data'] := 'yourdatahere';
  json['path01/path02/var01'] := 'value01';
  json['path01/path02/var02'] := 'value02';
  CustomHeader['ThisIsCustomHeader'] := 'datacustomheader';


  //---
  Response.Content := json.AsJSON;
  json.Free;
end;



end.

