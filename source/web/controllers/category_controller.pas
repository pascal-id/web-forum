unit category_controller;

{$mode objfpc}{$H+}

interface

uses
  forum_model, category_model, breadcrumb_controller,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TCategoryController = class(TMyCustomController)
  private
    FBreadCrumb: TBreadCrumb;
    FCategory: TCategoryModel;
    FForum: TForumModel;
    FForumAsArray: TJSONArray;
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

constructor TCategoryController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FBreadCrumb := TBreadCrumb.Create;
  FCategory := TCategoryModel.Create();
  FForum := TForumModel.Create();
end;

destructor TCategoryController.Destroy;
begin
  FCategory.Free;
  FForum.Free;
  FBreadCrumb.Free;
  inherited Destroy;
end;

// Init First
procedure TCategoryController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TCategoryController.Get;
var
  categoryId: Integer;
  ogURL: String;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  categoryId:= _GET['$1'].AsInteger;
  if categoryId = 0 then
    Redirect('/forum');

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');

  if not FCategory.IsExist(categoryId) then
    Redirect('/forum');

  // Get Forum List
  FForumAsArray := FForum.ByCategory(categoryId);
  ThemeUtil.Assign('$CategoryTitle', FCategory.CategoryTitle);
  ThemeUtil.Assign('$Title', FCategory.CategoryTitle);

  // Open graph
  ogURL := BaseURL + 'forum/category/' + categoryId.ToString + '/' + GenerateSlug(FCategory.CategoryTitle);
  SetOpenGraph(FCategory.CategoryTitle, BaseURL + FORUM_DEFAULT_OGIMAGE, ogURL);


  // Generate BreadCrumb
  FBreadCrumb.Add(FCategory.CategoryTitle, '', True);
  ThemeUtil.Assign('$BreadCrumb', FBreadCrumb.AsHTML);


  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TCategoryController.Post;
begin
end;

function TCategoryController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  ThemeUtil.AssignVar['$Forums'] := @FForum.Data;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/forum/category.html');
end;

end.



