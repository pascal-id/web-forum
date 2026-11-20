unit topic_new_controller;

{$mode objfpc}{$H+}

interface

uses
  breadcrumb_controller, forum_model, topic_model,
  Classes, SysUtils, html_lib, fastplaz_app, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TTopicNewController = class(TMyCustomController)
  private
    FForumId: Integer;
    FBreadCrumb: TBreadCrumb;
    FForum: TForumModel;
    FTopics: TTopicModel;
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

uses theme_controller, common, common_lib, html_sanitizer_lib;

constructor TTopicNewController.CreateNew(AOwner: TComponent;
  CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FBreadCrumb := TBreadCrumb.Create;
  FForum := TForumModel.Create();
  FTopics := TTopicModel.Create();
end;

destructor TTopicNewController.Destroy;
begin
  FTopics.Free;
  FForum.Free;
  FBreadCrumb.Free;
  inherited Destroy;
end;

// Init First
procedure TTopicNewController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TTopicNewController.Get;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  FForumId := _GET['$1'].ToInteger;
  if FForumId = 0 then
  begin
    Redirect('/forum/');
    Exit;
  end;

  DataBaseInit();
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  FForum.AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id', ['cat_title']);
  if not FForum.FindFirst(['forum_id='+FForumId.ToString, 'auth_read=0']) then
  begin
    Redirect('/forum/', 'Forum not Found');
    Exit;
  end;

  ThemeUtil.Assign('$CategoryTitle', FForum.CategoryTitle);
  ThemeUtil.Assign('$ForumName', FForum.ForumName);
  ThemeUtil.Assign('$ForumId', FForumId.ToString);
  ThemeUtil.Assign('$Title', 'Create new topic at ' + FForum.ForumName);


  // Generate BreadCrumb
  FBreadCrumb.Add(FForum.CategoryTitle, BaseURL + 'forum/category/' +
    FForum.CategoryId.ToString + '/' + HTMLUtil.Permalink(FForum.CategoryTitle));
  FBreadCrumb.Add(FForum.ForumName, BaseURL + 'forum/' +
    FForumId.ToString + '/' + HTMLUtil.Permalink(FForum.ForumName), True);
  ThemeUtil.Assign('$BreadCrumb', FBreadCrumb.AsHTML);

  ThemeUtil.AddCSS(BaseURL + 'modules/forum/css/style.css');

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TTopicNewController.Post;
var
  topicTitle, topicMessage: String;
  json: TJSONUtil;
begin
  Response.ContentType := 'application/json';
  // wajib login
  if not GetUserSessionInfo then
  begin
    OutputJson(401, ERR_NOT_PERMITTED);
    Exit;
  end;
  if not IsValidCSRFToken then
  begin
    OutputJson(403, ERR_CSRF_INVALID);
    Exit;
  end;
  SetThemeParameter;

  FForumId := _GET['$1'].ToInteger;
  if FForumId = 0 then
  begin
    Redirect('/forum/');
    Exit;
  end;

  topicTitle := CleanTitle(_POST['title']);
  topicMessage := UrlDecode(_POST['message']);
  if topicTitle.IsEmpty or topicMessage.IsEmpty then
  begin
    OutputJson(400, ERR_INVALID_PARAMETER);
    Exit;
  end;

  DataBaseInit();
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  // forum harus ada, aktif (tidak dikunci) dan boleh di-post member biasa
  // (phpBB auth_post: 0 = semua, 1 = member terdaftar, >1 = moderator/admin)
  if not FForum.FindFirst(['forum_id=' + FForumId.ToString, 'auth_read=0',
    'forum_status=0', 'auth_post<=1']) then
  begin
    OutputJson(403, ERR_NOT_PERMITTED);
    Exit;
  end;

  if not FTopics.Add(UserSession.UserId, FForumId, topicTitle, topicMessage) then
  begin
    OutputJson(400, TOPIC_SAVE_ERROR);
    Exit;
  end;

  json := TJSONUtil.Create;
  json['code'] := 0;
  json['topic_id'] := FTopics.TopicId;
  json['topic_slug'] := GenerateSlug(topicTitle);
  json['forum_id'] := FForumId;

  // Respose
  Response.Content := json.AsJSON;
  json.Free;
end;

function TTopicNewController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/forum/topic_edit.html');
end;


end.

