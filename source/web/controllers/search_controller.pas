unit search_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TSearchController = class(TMyCustomController)
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

constructor TSearchController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TSearchController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TSearchController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  GetUserSessionInfo;
  SetThemeParameter;
end;

// GET Method Handler
procedure TSearchController.Get;
var
  query: String;
begin
  query := _GET['q'];
  ThemeUtil.Assign('$Query', query);

  ThemeUtil.Assign('$Title', 'Search '+query);

  SetOpenGraph('Search', BaseURL + SEARCH_DEFAULT_OGIMAGE, BaseURL + 'search/');

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TSearchController.Post;
begin
end;

function TSearchController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/search/home.html');
end;


end.




