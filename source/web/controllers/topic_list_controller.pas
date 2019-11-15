unit topic_list_controller;
{
  USAGE:

  [x] Forum List
  http://www.pascal-id.test/forum/{forum-id}/{forum-name}

}

{$mode objfpc}{$H+}

interface

uses
  breadcrumb_controller, forum_model, topic_model,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type
  TTopicListController = class(TMyCustomController)
  private
    FBreadCrumb: TBreadCrumb;
    FForum: TForumModel;
    FTopics: TTopicModel;
    FTopicsAsArray: TJSONArray;
    function Tag_MainContent_Handler(const TagName: string; Params: TStringList
      ): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common, common_lib;

constructor TTopicListController.CreateNew(AOwner: TComponent;
  CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FBreadCrumb := TBreadCrumb.Create;
  FForum := TForumModel.Create();
  FTopics := TTopicModel.Create();
end;

destructor TTopicListController.Destroy;
begin
  FTopics.Free;
  FForum.Free;
  FBreadCrumb.Free;
  inherited Destroy;
end;

// Init First
procedure TTopicListController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TTopicListController.Get;
var
  forumId, categoryId, maxPageNumber: Integer;
  forumURL, ogURL: String;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  Lang := GetLang;
  Page := GetPage;
  forumId := _GET['$1'].AsInteger;

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');

  FForum.AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id', ['cat_title']);
  if not FForum.FindFirst(['forum_id='+forumId.ToString, 'auth_read=0']) then
  begin
    Redirect('/forum/', 'Forum not Found');
  end;

  maxPageNumber := (FForum['forum_topics'] div TOPIC_DEFAULT_LIMIT) - 1;

  ThemeUtil.Assign('$CategoryTitle', FForum.CategoryTitle);
  ThemeUtil.Assign('$ForumName', FForum.ForumName);
  ThemeUtil.Assign('$ForumId', forumId.ToString);
  ThemeUtil.Assign('$Title', FForum.ForumName);
  forumURL := BaseURL + 'forum/' + forumId.ToString + '/' + GenerateSlug(FForum.ForumName);
  ThemeUtil.Assign('$ForumUrl', forumURL);

  // Get Topic List
  FTopicsAsArray := FTopics.List(forumId, Page);

  // Open graph
  ogURL := forumURL;
  if Page > 1 then
    ogURL := ogURL + '?page=' + i2s(Page);
  SetOpenGraph(FForum.ForumName, BaseURL + FORUM_DEFAULT_OGIMAGE, ogURL);

  // Generate BreadCrumb
  FBreadCrumb.Add(FForum.CategoryTitle, BaseURL + 'forum/category/' +
    FForum.CategoryId.ToString + '/' + HTMLUtil.Permalink(FForum.CategoryTitle));
  FBreadCrumb.Add(FForum.ForumName, BaseURL + 'forum/' +
    forumId.ToString + '/' + HTMLUtil.Permalink(FForum.ForumName), True);
  ThemeUtil.Assign('$BreadCrumb', FBreadCrumb.AsHTML);

  // Pagination
  forumURL := forumURL + '?page=';
  ThemeUtil.Assign('$Pagination', GeneratePagination(Page, maxPageNumber, forumURL));


  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TTopicListController.Post;
begin
end;

function TTopicListController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  ThemeUtil.AssignVar['$Topics'] := @FTopics.Data;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/forum/topic_list.html');
end;


end.

