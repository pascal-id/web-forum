unit forum_home_controller;

{$mode objfpc}{$H+}

interface

uses
  forum_model,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers,
  json_helpers;

type

  { TForumController }

  TForumController = class(TMyCustomController)
  private
    FForum: TForumModel;
    FForumAsArray: TJSONArray;
    function Tag_MainContent_Handler(const TagName: string;
      Params: TStringList): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
    function ViewAsList(AContent: TJSONArray; AIsRandom: Boolean = False): string;
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;

    // Block Handler
    procedure DoBlockController(Sender: TObject; FunctionName: string;
      Parameter: TStrings; var ResponseString: string);

  end;

implementation

uses theme_controller, common, topic_model, datetime_lib, common_lib;

constructor TForumController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  OnBlockController := @DoBlockController;
  FForum := TForumModel.Create();
end;

destructor TForumController.Destroy;
begin
  FForum.Free;
  inherited Destroy;
end;

// Init First
procedure TForumController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
end;

function TForumController.ViewAsList(AContent: TJSONArray; AIsRandom: Boolean
  ): string;
var
  i, topicId, forumId: integer;
  topicTitle, threadUrl, forumName, forumUrl: string;
  dt: TDateTime;
  isArchiveActive: Boolean;
  archivedTopic: Integer;
begin
  isArchiveActive := False;
  Result := '<ul>';

  for i := 0 to AContent.Count - 1 do
  begin
    archivedTopic := AContent.Items[i].ValueOfName('archived').AsInteger;
    if not AIsRandom then
    begin
      if archivedTopic=0 then
      begin
        if not isArchiveActive then
        begin
          isArchiveActive := True;
          Result += '<li class="archive"><span class="archive">Archive</span></li>';
        end;
      end;
    end;

    dt := UnixToDateTime(AContent.Items[i].ValueOfName('topic_time').AsInt64);
    topicId := AContent.Items[i].ValueOfName('topic_id').AsInteger;
    topicTitle := AContent.Items[i].ValueOfName('topic_title').AsString;
    forumId := AContent.Items[i].ValueOfName('forum_id').AsInteger;
    forumName := AContent.Items[i].ValueOfName('forum_name').AsString;
    forumUrl := BaseURL + 'forum/' + forumId.ToString + '/' + HTMLUtil.Permalink(forumName);
    threadUrl := BaseURL + 'thread/' + HTMLUtil.Permalink(forumName) +
      '/' + topicId.ToString + '/' + HTMLUtil.Permalink(topicTitle);

    Result += '<li>';

    Result += '<a href="' + threadUrl + '">';
    Result += topicTitle;
    Result += '</a>';

    Result += '<br /><span class="small">';
    Result += 'by ' + AContent.Items[i].ValueOfName('username').AsString;
    Result += ' in ';
    Result += '<a href="' + forumUrl + '">';
    Result += forumName;
    Result += '</a>';
    Result += ' ' + DateTimeHuman(dt);
    Result += '</span>';

    Result += '</li>';
  end;
  Result += '</ul>';

end;

// GET Method Handler
procedure TForumController.Get;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  ThemeUtil.Assign('$Title', 'Forum');
  FForumAsArray := FForum.ListDetail;

  SetOpenGraph('Forum Pascal Indonesia', BaseURL + FORUM_DEFAULT_OGIMAGE, BaseURL + 'forum/');

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TForumController.Post;
begin
end;

procedure TForumController.DoBlockController(Sender: TObject;
  FunctionName: string; Parameter: TStrings; var ResponseString: string);
var
  topic: TTopicModel;
  topicAsArray: TJSONArray;
  i, topicId, forumId: integer;
  topicTitle, threadUrl, forumName, forumUrl: string;
begin
  case FunctionName of
    'lasttopic':
    begin
      topic := TTopicModel.Create;
      topicAsArray := topic.RecentTopic(10);
      ResponseString := ViewAsList(topicAsArray);
      topic.Free;
    end;
    'randomtopic':
    begin
      topic := TTopicModel.Create;
      topicAsArray := topic.Random(10);
      ResponseString := ViewAsList(topicAsArray, True);
      topic.Free;
    end;
  end;

end;

function TForumController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
var
  i, lastCatId, j: integer;
  s, categoryTitle, forumName: string;
  html: TStringList;
begin
  lastCatId := 0;
  html := TStringList.Create;
  for i := 0 to FForumAsArray.Count - 1 do
  begin
    j := FForumAsArray.Items[i].ValueOfName('cat_id').AsInteger;
    if j <> lastCatId then
    begin
      if lastCatId <> 0 then
        html.Add('</ul>');
      lastCatId := j;
      categoryTitle := FForumAsArray.Items[i].ValueOfName('cat_title').AsString;
      s := '<b class="category_title"><a href="' + BaseURL + 'forum/category/' +
        lastCatId.ToString + '/' + HTMLUtil.Permalink(categoryTitle) + '">';
      s += categoryTitle;
      s += '</a></b>';
      html.Add(s);
      html.Add('<ul>');
    end
    else
    begin
    end;

    forumName := FForumAsArray.Items[i].ValueOfName('forum_name').AsString;
    s := '<li><a href="' + BaseURL + 'forum/';
    s += FForumAsArray.Items[i].ValueOfName('forum_id').AsString;
    s += '/' + HTMLUtil.Permalink(forumName) + '">';
    s += forumName;
    s += '</a>';
    s += '<span class="small">, ' + FForumAsArray.Items[i].ValueOfName(
      'forum_topics').AsString + ' topics</span>';
    s += '<br /><span class="small">' + FForumAsArray.Items[i].ValueOfName(
      'forum_desc').AsString + '</span>';
    s += '</li>';
    html.Add(s);

  end;

  ThemeUtil.Assign('$ForumAsHTML', html.Text);
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/forum/home.html');
end;


end.

