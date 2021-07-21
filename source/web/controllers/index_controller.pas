unit index_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TIndexController = class(TMyCustomWebModule)
  private
    function Tag_MainContent_Handler(const TagName: string;
      Params: TStringList): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common, common_lib;

constructor TIndexController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TIndexController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TIndexController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TIndexController.Get;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  Lang := GetLang;
  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  ThemeUtil.AddCSS(BaseURL + 'modules/home/css/style.css');
  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler

  ThemeUtil.TrimWhiteSpace:= False;
  Response.Content := ThemeUtil.Render(nil, 'home');
end;

// POST Method Handler
procedure TIndexController.Post;
begin
  Redirect('/');
end;

function TIndexController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/home/home.html');
end;


end.




