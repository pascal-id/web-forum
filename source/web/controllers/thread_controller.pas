unit thread_controller;
{
  USAGE:

  [x] Thread History
  http://www.pascal-id.test/thread/category-name/{ThreadId}/{ThreadName}?page=2#post-123

}

{$mode objfpc}{$H+}

interface

uses
  topic_model, breadcrumb_controller,
  Classes, SysUtils, html_lib, fastplaz_app, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TThreadController }

  TThreadController = class(TMyCustomController)
  private
    FLimit: integer;
    FTopics: TTopicModel;
    FBreadCrumb: TBreadCrumb;
    // post sudah dirender & disanitasi oleh TTopicModel.Thread
    FThreadAsArray: TJSONArray;
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

constructor TThreadController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FTopics := TTopicModel.Create();
  FBreadCrumb := TBreadCrumb.Create;
  FThreadAsArray := nil;
  Page := 1;
end;

destructor TThreadController.Destroy;
begin
  FBreadCrumb.Free;
  FTopics.Free;
  if Assigned(FThreadAsArray) then
    FThreadAsArray.Free;
  inherited Destroy;
end;

// Init First
procedure TThreadController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TThreadController.Get;
var
  threadID: integer;
  ogURL, threadURL, s: string;
  threadPostTime: Integer;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  Lang := GetLang;
  Page := GetPage;
  threadID := _GET['$2'].AsInteger;
  FLimit := THREAD_DEFAULT_LIMIT;

  DataBaseInit();
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  FThreadAsArray := FTopics.Thread(threadID, Page, FLimit);
  if FThreadAsArray.Count = 0 then
  begin
    Redirect('/forum/', 'Topic not Found');
    Exit;
  end;

  ThemeUtil.Assign('$TopicName', FTopics.ThreadTitle);
  ThemeUtil.Assign('$Title', 'Thread: ' + FTopics.ThreadTitle);
  ThemeUtil.Assign('$Obsolete', FTopics.Obsolete.ToString);

  threadPostTime := FTopics['post_time'];
  s := '2019-11-10 10:11:00';
  if threadPostTime < DateTimeToUnix(s.AsDateTime) then
    ThemeUtil.Assign('$Prefix', 'Arsip: ');

  // Generate BreadCrumb
  FBreadCrumb.Add(FTopics.CategoryTitle, BaseURL + 'forum/category/' +
    FTopics.CategoryId.ToString + '/' + HTMLUtil.Permalink(FTopics.CategoryTitle));
  FBreadCrumb.Add(FTopics.ForumTitle, BaseURL + 'forum/' +
    FTopics.ForumId.ToString + '/' + HTMLUtil.Permalink(FTopics.ForumTitle));
  //FBreadCrumb.Add(FTopics.ThreadTitle, '', True);
  ThemeUtil.Assign('$BreadCrumb', FBreadCrumb.AsHTML);

  // facebook open graph
  threadURL := BaseURL + 'thread/' + GenerateSlug(FTopics.ForumTitle) +
    '/' + i2s(threadID) + '/' + GenerateSlug(FTopics.ThreadTitle) + '/';
  ThemeUtil.Assign('$ThreadUrl', threadURL);
  ogURL := threadURL;
  if FTopics.CurrentPage > 1 then
    ogURL := ogURL + '?page=' + i2s(FTopics.CurrentPage);
  SetOpenGraph('Thread: ' + FTopics.ThreadTitle, BaseURL + THREAD_DEFAULT_OGIMAGE, ogURL);

  // Pagination
  threadURL := threadURL + '?page=';
  ThemeUtil.Assign('$Pagination', GeneratePagination(FTopics.CurrentPage, FTopics.MaxNumberOfPage, threadURL));

  ThemeUtil.Assign('$ThreadId', threadID.ToString);
  ThemeUtil.Assign('$ThreadSlug', GenerateSlug(FTopics.threadTitle));
  ThemeUtil.Assign('$PageNumber', FTopics.CurrentPage.ToString);
  ThemeUtil.Assign('$MaxNumberOfPage', FTopics.MaxNumberOfPage.ToString);
  ThemeUtil.Assign('b', FTopics.MaxNumberOfPage.ToString);

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  ThemeUtil.TrimWhiteSpace:= False;
  Response.Content := ThemeUtil.Render();
  FTopics.AddHit(threadID);
end;

// POST Method Handler
procedure TThreadController.Post;
var
  topicId: Integer;
  replyMessage: String;
  json: TJSONUtil;
begin
  Response.ContentType := 'application/json';
  GetUserSessionInfo;
  SetThemeParameter;

  if UserSession.IsExpired then
  begin
    OutputJson(400, ERR_NOT_PERMITTED);
    Exit;
  end;

  topicId := s2i(_POST['id']);
  replyMessage := UrlDecode(_POST['message']);

  if (topicId = 0) or (replyMessage.IsEmpty) then
  begin
    OutputJson(400, ERR_INVALID_PARAMETER);
    Exit;
  end;

  DataBaseInit;
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  if not FTopics.ReplyThread(topicId, UserSession.UserId, replyMessage) then
  begin
    OutputJson(400, ERR_UNKNOWN);
    Exit;
  end;

  json := TJSONUtil.Create;
  json['code'] := 0;
  json['post_id'] := FTopics.ThreadPostId;
  json['message'] := OK;
  Response.Content:= json.AsJSON;
  json.Free;
end;

function TThreadController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  ThemeUtil.AssignVar['$Threads'] := @FThreadAsArray;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/forum/thread.html');
  Result := ReplaceFromLegacy(Result);
  Result := Result.Replace('\''', '''');
end;

end.




