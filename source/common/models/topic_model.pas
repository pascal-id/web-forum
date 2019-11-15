unit topic_model;

{$mode objfpc}{$H+}

interface

uses
  fpjson, common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TTopicModel }

  TTopicModel = class(TSimpleModel)
  private
    FThreadPostId: Integer;
    FTopicId: Integer;
  public
    Obsolete: Integer;
    CurrentPage, NumberOfReplies, MaxNumberOfPage, CategoryId, ForumId: integer;
    CategoryTitle, ForumTitle, ThreadTitle: string;
    constructor Create(const DefaultTableName: string = '');

    function LastTopic(ALimit: integer = 0): TJSONArray;
    function List(AForumId: integer; APage: integer = 1;
      ALimit: integer = TOPIC_DEFAULT_LIMIT): TJSONArray;
    function RecentTopic(ALimit: integer = 0): TJSONArray;
    function Random(ALimit: integer = 0): TJSONArray;
    function LastThread(ATopicID: integer;
      ALimit: integer = THREAD_DEFAULT_LIMIT): TJSONArray;
    function Thread(ATopicID: integer; APage: integer = 1;
      ALimit: integer = THREAD_DEFAULT_LIMIT): TJSONArray;

    function Add(AUserId: Integer; AForumId: Integer; ATitle, AMessage: String): Boolean;
    function SearchTitle(AKeyword: String; ALimit: Integer = TOPIC_DEFAULT_LIMIT): Boolean;
    function ReplyThread(ATopicId: Integer; AReplyBy: Integer; AReplyMessage: String): Boolean;
    procedure AddHit(ATopicId: Integer);
    procedure AddReplyCounter(ATopicId: Integer);

    property TopicId: Integer read FTopicId;
    property ThreadPostId: Integer read FThreadPostId;
  end;

implementation

uses json_helpers, topic_post_model;

constructor TTopicModel.Create(const DefaultTableName: string = '');
begin
  inherited Create('phpbb_topics');
  primaryKey := 'topic_id';
  FieldPrefix := '';
end;

function TTopicModel.LastTopic(ALimit: integer): TJSONArray;
begin
  AddJoin('users', 'uid', 'topic_poster', []);
  AddJoin('phpbb_forums', 'forum_id', 'phpbb_topics.forum_id',
    ['cat_id', 'forum_id', 'forum_name']);
  AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id',
    ['cat_title category_name']);
  if Find(['topic_status=0'], 'topic_time DESC', ALimit,
    'topic_id, topic_title, topic_time, users.username') then
  begin
    Result := AsJsonArray(False);
  end
  else
    Result := TJSONArray.Create;
end;

function TTopicModel.List(AForumId: integer; APage: integer; ALimit: integer
  ): TJSONArray;
var
  offsetThread: Integer;
  selectTopics: String;
begin
  Result := TJSONArray.Create;
  if ALimit = 0 then
    ALimit := TOPIC_DEFAULT_LIMIT;
  offsetThread := APage;
  if offsetThread > 0 then
  begin
    offsetThread := (APage - 1) * ALimit;
  end;

  selectTopics := 'SELECT topic_id id, topic_title title, topic_time time, users.username, topic_views views, topic_replies replies'
    + #10'FROM phpbb_topics phpbb_topics'
    + #10'LEFT JOIN users ON users.uid=topic_poster'
    + #10'LEFT JOIN phpbb_forums ON phpbb_forums.forum_id=phpbb_topics.forum_id'
    + #10'LEFT JOIN phpbb_categories ON phpbb_categories.cat_id=phpbb_forums.cat_id'
    + #10'WHERE topic_status=0 AND phpbb_forums.forum_id=' + AForumId.ToString
    + #10'ORDER BY topic_time DESC'
    + #10'limit ' + offsetThread.ToString + ',' + ALimit.ToString;

  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectTopics;
  Data.Open;
  DataToJSON(Data, Result, False);
end;

function TTopicModel.RecentTopic(ALimit: integer): TJSONArray;
var
  fieldList, selectTopics: string;
begin
  Result := TJSONArray.Create;
  if ALimit = 0 then
    ALimit := TOPIC_DEFAULT_LIMIT;
  fieldList := 'recent_posts.topic_id, topic_title, topic_time, username, recent_posts.forum_id, forum_name, archived';
  selectTopics := 'SELECT ' + fieldList
    + #10'FROM (SELECT *'
    + #10'FROM phpbb_posts'
    + #10'GROUP BY topic_id'
    + #10'ORDER BY post_time DESC'
    + #10'LIMIT 30) as recent_posts'
    + #10'LEFT JOIN phpbb_topics ON phpbb_topics.topic_id=recent_posts.topic_id'
    + #10'LEFT JOIN users ON users.uid=recent_posts.poster_id'
    + #10'LEFT JOIN phpbb_forums ON phpbb_forums.forum_id=recent_posts.forum_id'
    + #10'WHERE topic_status=0'
    + #10'LIMIT ' + ALimit.ToString
    + ';';
  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectTopics;
  Data.Open;
  DataToJSON(Data, Result, False);
end;

function TTopicModel.Random(ALimit: integer): TJSONArray;
var
  selectTopics: String;
begin
  Result := TJSONArray.Create;
  if ALimit = 0 then
    ALimit := THREAD_DEFAULT_LIMIT;
  selectTopics := 'SELECT topic_id, topic_title, topic_time, username, random_topics.forum_id, phpbb_forums.forum_name, archived '
    + #10'FROM ('
    + #10'SELECT *'
    + #10'FROM phpbb_topics phpbb_topics'
    + #10'WHERE topic_status=0'
    + #10'GROUP BY phpbb_topics.topic_id'
    + #10'ORDER BY RAND()'
    + #10'limit ' + ALimit.ToString
    + #10') random_topics'
    + #10'LEFT JOIN users ON users.uid=topic_poster'
    + #10'LEFT JOIN phpbb_forums ON phpbb_forums.forum_id=random_topics.forum_id'
    + #10';';

  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectTopics;
  Data.Open;
  DataToJSON(Data, Result, False);
end;

// ex: 8035
function TTopicModel.LastThread(ATopicID: integer; ALimit: integer): TJSONArray;
var
  selectThread: TStringList;
begin
  Result := TJSONArray.Create;
  if ALimit = 0 then
    ALimit := THREAD_DEFAULT_LIMIT;
  selectThread := TStringList.Create;
  selectThread.Text := 'SELECT * FROM (' +
    #10'SELECT phpbb_posts.post_id, post_time, users.username, post_text FROM phpbb_posts'
    + #10'JOIN phpbb_posts_text ON phpbb_posts_text.post_id=phpbb_posts.post_id' +
    #10'JOIN users ON users.uid=phpbb_posts.poster_id' +
    #10'WHERE topic_id=' + i2s(ATopicID) + #10'ORDER BY post_time DESC' +
    #10'LIMIT ' + i2s(ALimit) + #10') thread_recent ORDER BY post_id ASC';
  QueryOpenToJson(selectThread.Text, Result, False);
  selectThread.Free;
end;

function TTopicModel.Thread(ATopicID: integer; APage: integer;
  ALimit: integer): TJSONArray;
var
  i, indexField, offsetThread: integer;
  s, selectThread: string;
begin
  Result := TJSONArray.Create;
  AddJoin('phpbb_forums', 'forum_id', 'phpbb_topics.forum_id', ['cat_id', 'forum_name']);
  AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id', ['cat_title']);
  if not Find(['topic_status=0', 'topic_id='+ATopicID.ToString]) then
    Exit;

  ThreadTitle := Value['topic_title'];
  CategoryId := Value['cat_id'];
  CategoryTitle := Value['cat_title'];
  ForumId := Value['forum_id'];
  ForumTitle := Value['forum_name'];
  Obsolete := Value['obsolete'];
  NumberOfReplies := Value['topic_replies'];

  if ALimit = 0 then
    ALimit := THREAD_DEFAULT_LIMIT;
  MaxNumberOfPage := (numberOfReplies div ALimit) + 1;
  if APage > maxNumberOfPage then
    APage := maxNumberOfPage;
  CurrentPage := APage;

  offsetThread := APage;
  if offsetThread > 0 then
  begin
    offsetThread := (APage - 1) * ALimit;
  end;

  if Data.Active then
    Data.Close;
  selectThread :=
    #10'SELECT phpbb_posts.post_id, post_time, users.username, md5(users.email) gravatar, post_text '
    + #10'FROM phpbb_posts'
    + #10'JOIN phpbb_posts_text ON phpbb_posts_text.post_id=phpbb_posts.post_id' +
    #10'JOIN users ON users.uid=phpbb_posts.poster_id' +
    #10'WHERE topic_id=' + i2s(ATopicID) + #10'ORDER BY post_time ASC' +
    #10'limit ' + offsetThread.ToString + ',' + ALimit.ToString;
  Data.SQL.Text := selectThread;
  Data.Open;
  DataToJSON(Data, Result, False);

  // reformat body text
  for i := 0 to Result.Count - 1 do
  begin
    indexField := Result.Items[i].IndexOfName('post_text');
    if indexField <> -1 then
    begin
      s := Result.Items[i].Items[indexField].AsString;
      try
        s := FormatTextLikeForum(s);
        //s := s.Replace('\"', '"');
        //s := s.Replace('\r\n', #10);
        s := s.Replace(#10#10, #10);
        Result.Items[i].Items[indexField].AsString := s;
      except
      end;
    end;
  end;
end;

function TTopicModel.Add(AUserId: Integer; AForumId: Integer; ATitle,
  AMessage: String): Boolean;
var
  insertTopic: String;
begin
  Result := False;
  if (AUserId=0) or (AForumId=0) or ATitle.IsEmpty or AMessage.IsEmpty then
    Exit;

  New;
  Value['topic_poster'] := AUserId;
  Value['forum_id'] := AForumId;
  Value['topic_title'] := ATitle;
  Value['topic_time'] := DateTimeToUnix(Now);
  Value['topic_status'] := 0;
  if Save() then
  begin
    FTopicId := LastInsertID;
    with TTopicPostModel.Create() do
    begin
      Add(FTopicId, AForumId, AUserId, AMessage);
      FThreadPostId := PostId;
      Free;
    end;
    Result := True;
  end;
end;

function TTopicModel.SearchTitle(AKeyword: String; ALimit: Integer): Boolean;
var
  i: Integer;
  s, whereQuery, prefixWhere: String;
  keywordList: TStrings;
begin
  Result := False;
  if AKeyword.IsEmpty then
    Exit;

  // Simple extract keyword
  keywordList := Explode(AKeyword, ' ');
  whereQuery := '(topic_status=0 AND (';
  prefixWhere := '';
  if keywordList.Count > 1 then
  begin
    keywordList.Insert(0, AKeyword);
  end;
  for i:=0 to keywordList.Count-1 do
  begin
    s := keywordList[i];
    if s.IndexOf('+') = 0 then
    begin
      if i > 0 then prefixWhere := ' AND ';
      s := s.Substring(1);
      whereQuery +=  ' ' + prefixWhere + '  topic_title LIKE ''%'+s+'%'''
    end
    else
    begin
      if i > 0 then prefixWhere := ' OR ';
      whereQuery +=  ' ' + prefixWhere + ' topic_title LIKE ''%'+keywordList[i]+'%''';
    end;
  end;
  whereQuery += '))';

  if Data.Active then
    Data.Close;
  Data.SQL.Text := 'SELECT topic_id, topic_title, topic_poster '
    + #10'FROM phpbb_topics '
    + #10'WHERE ' + whereQuery
    + #10'LIMIT ' + ALimit.ToString;
  Data.Open;
  Result := True;
end;

function TTopicModel.ReplyThread(ATopicId: Integer; AReplyBy: Integer;
  AReplyMessage: String): Boolean;
begin
  Result := False;
  with TTopicPostModel.Create() do
  begin
    if Add(ATopicId, 0, AReplyBy, AReplyMessage) then
    begin
      FThreadPostId := PostId;
      AddReplyCounter(ATopicId);
      Result := True;
    end;
    Free;
  end;
end;

procedure TTopicModel.AddHit(ATopicId: Integer);
begin
  if ATopicId = 0 then
    Exit;
  QueryExec('UPDATE phpbb_topics SET topic_views=topic_views+1 WHERE topic_id='+ATopicId.ToString+';');
end;

procedure TTopicModel.AddReplyCounter(ATopicId: Integer);
begin
  if ATopicId = 0 then
    Exit;
  QueryExec('UPDATE phpbb_topics SET topic_replies=topic_replies+1 WHERE topic_id='+ATopicId.ToString+';');
end;

end.


