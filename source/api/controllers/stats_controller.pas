unit stats_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcgi, fpjson, json_lib, HTTPDefs, fastplaz_handler, 
    database_lib, string_helpers, dateutils, datetime_helpers;

type
  TStatsModule = class(TMyCustomWebModule)
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

constructor TStatsModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TStatsModule.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TStatsModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest
  );
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TStatsModule.Get;
begin
  Response.Content := '{}';
end;

// POST Method Handler
procedure TStatsModule.Post;
begin
end;



end.

