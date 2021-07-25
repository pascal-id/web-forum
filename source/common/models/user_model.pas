unit user_model;

{$mode objfpc}{$H+}

interface

uses
  fpjson, common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers,
  json_helpers;

{$include ../../common/common.inc}

type

  { TUserModel }

  TUserModel = class(TSimpleModel)
  private
    FCurrentUserName: String;
    function getArticleCount: Integer;
    function getCommentCount: Integer;
    function getLevelName: String;
    function getPostCount: Integer;
    function getRankName: String;
  public
    constructor Create(const DefaultTableName: string = '');

    function FindByUserName(const AUserName: String): Boolean;
    function FindByEmail(const AEmail: String): Boolean;
    function Activity(AUserId: integer; AUserName: String): TJSONArray;
    function Comments(AUserId: integer; AUserName: String): TJSONArray;
    function AddFromFacebook(AId: Int64; AFirstName, ALastName: String; AEmail: String; AExistingUserID: Integer = 0): Boolean;
    function AddMapping(ATypeId, AUserId: Integer; AReferenceId: String; AEmail: String): boolean;
    function IsAdministrator(AUserId: Integer): Boolean;

    property CurrentUserName: String read FCurrentUserName;
    property RankName: String read getRankName;
    property LevelName: String read getLevelName;
    property ArticleCount: Integer read getArticleCount;
    property PostCount: Integer read getPostCount;
    property CommentCount: Integer read getCommentCount;
  end;

implementation

uses common_lib;

function TUserModel.getArticleCount: Integer;
var
  userName: String;
  json: TJSONArray;
begin
  Result := 0;
  userName := Data['username'];
  json := TJSONArray.Create;
  if QueryOpenToJson('SELECT count(nid) count FROM news WHERE contributor="'+userName+'"',
    json, False) then
  begin
    if json.Count > 0 then
    begin
      Result := json.Items[0].Items[0].AsInteger;
    end;
  end;
  json.Free;
end;

function TUserModel.getCommentCount: Integer;
var
  userId: Integer;
  json: TJSONArray;
begin
  Result := 0;
  userId := Data['uid'];
  json := TJSONArray.Create;
  if QueryOpenToJson('SELECT count(post_id) count FROM phpbb_posts WHERE poster_id='+userId.ToString,
    json, False) then
  begin
    if json.Count > 0 then
    begin
      Result := json.Items[0].Items[0].AsInteger;
    end;
  end;
  json.Free;
end;

function TUserModel.getLevelName: String;
var
  json: TJSONArray;
begin
  Result := 'no level';
  if QueryOpenToJson('', json, False) then
  begin

  end;

end;

function TUserModel.getPostCount: Integer;
var
  userId: Integer;
  json: TJSONArray;
begin
  Result := 0;
  userId := Data['uid'];
  json := TJSONArray.Create;
  if QueryOpenToJson('SELECT count(topic_id) count FROM phpbb_topics WHERE topic_poster='+userId.ToString,
    json, False) then
  begin
    if json.Count > 0 then
    begin
      Result := json.Items[0].Items[0].AsInteger;
    end;
  end;
  json.Free;
end;

function TUserModel.getRankName: String;
var
  rankIndex: Integer;
  json: TJSONArray;
begin
  Result := '';
  rankIndex := Data['rank'];
  if rankIndex = 0 then
    Exit;
  json := TJSONArray.Create;
  if QueryOpenToJson('SELECT rank_title FROM phpbb_ranks WHERE rank_id='+rankIndex.ToString,
    json, False) then
  begin
    if json.Count > 0 then
    begin
      Result := json.Items[0].Items[0].AsString;
    end;
  end;
  json.Free;
end;

constructor TUserModel.Create(const DefaultTableName: string = '');
begin
  inherited Create( DefaultTableName); // table name = users
end;

function TUserModel.FindByUserName(const AUserName: String): Boolean;
begin
  Result := FindFirst(['`username`="'+AUserName+'"', '`activated`=0'], '',
    'uid, username, email, md5(email) gravatar, regdate, storynum, lastvisit, from_unixtime(lastvisit) lastvisit_date,'
    + 'post_count, signature, `level`, `rank`, user_from');
end;

function TUserModel.FindByEmail(const AEmail: String): Boolean;
begin
  Result := FindFirst(['email="'+AEmail+'"'], '',
    'uid, username, email, md5(email) gravatar, regdate, storynum, lastvisit, '
    + 'post_count, signature, level, rank, user_from');
end;

function TUserModel.Activity(AUserId: integer; AUserName: String): TJSONArray;
var
  i: Integer;
  s, selectTimeLine, url, timeLabel, timeLabelTemp: String;
  postDate: TDateTime;
begin
  Result := TJSONArray.Create;
  if AUserId = 0 then
    exit;

  //if not FindFirst(['uid='+AUserId.ToString]) then
  //  Exit;
  //userName := Data['username'];

  selectTimeLine := 'SELECT * FROM ('
    + #10'SELECT ''topic'' post_type, topic_id id, topic_title title, topic_time time_stamp, FROM_UNIXTIME(topic_time) date FROM phpbb_topics'
    + #10'WHERE topic_status=0 AND obsolete=1 AND topic_poster=' + AUserId.ToString
    + #10'UNION ALL'
    + #10'SELECT ''news'' post_type, nid id, title, unix_timestamp(`from`) time_stamp, `from` date FROM news'
    + #10'WHERE contributor="'+AUserName+'" AND published_status=0 AND `from` < "'+Now.AsString+'"'
    + #10'ORDER BY date desc'
    + #10'LIMIT 10'
    + #10') AS timeline ORDER BY date DESC LIMIT 10';

  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectTimeLine;
  Data.Open;
  DataToJSON(Data, Result, False);

  timeLabel := 'start';
  if Result.Count > 0 then
  begin
    s := Result.Items[0].Value['date'];
    postDate := s.AsDateTime;
    if YearsBetween(Now, postDate) > 2 then
    begin
      timeLabel := postDate.Format('yyyy');
    end else begin
      timeLabel := postDate.Format(ACTIVITY_MONTH_FORMAT);
    end;
  end;
  timeLabel := '---';

  for i := 0 to Result.Count-1 do
  begin
    url := '';

    // time label
    s := Result.Items[i].Value['date'];
    postDate := s.AsDateTime;
    timeLabelTemp := postDate.Format(ACTIVITY_DATE_FORMAT);
    if YearsBetween(Now, postDate) > 2 then
    begin
      timeLabelTemp := postDate.Format('yyyy');
      if timeLabelTemp = timeLabel then
        timeLabelTemp := ''
      else
        timeLabel := timeLabelTemp;
      TJSONObject(Result.Items[i]).Add('time_label',timeLabelTemp);
    end else begin
      timeLabelTemp := postDate.Format(ACTIVITY_MONTH_FORMAT);
      if timeLabelTemp = timeLabel then
        timeLabelTemp := ''
      else
        timeLabel := timeLabelTemp;
      TJSONObject(Result.Items[i]).Add('time_label',timeLabelTemp);
    end;



    // prefix
    if Result.Items[i].Value['post_type'] = 'topic' then
    begin
      url := 'thread/topic/' + Result.Items[i].Value['id'] +'/' +  GenerateSlug(Result.Items[i].Value['title']);
      TJSONObject(Result.Items[i]).Add('prefix','post');
    end;
    if Result.Items[i].Value['post_type'] = 'news' then
    begin
      url := 'news/' + Result.Items[i].Value['id'] +'/' + GenerateSlug(Result.Items[i].Value['title']);
      TJSONObject(Result.Items[i]).Add('prefix','share');
    end;

    TJSONObject(Result.Items[i]).Add('url',url);
  end;
end;

function TUserModel.Comments(AUserId: integer; AUserName: String): TJSONArray;
var
  i: Integer;
  url, selectComments: String;
begin
  Result := TJSONArray.Create;
  if AUserId = 0 then
    exit;

  selectComments := 'SELECT * FROM ('
    + #10'SELECT p.post_id id, p.topic_id, p.post_time date, t.topic_title title, pt.post_text text'
    + #10'FROM phpbb_posts p'
    + #10'LEFT JOIN phpbb_topics t ON t.topic_id=p.topic_id'
    + #10'LEFT JOIN phpbb_posts_text pt ON pt.post_id=p.post_id'
    + #10'WHERE t.topic_status=0 AND poster_id=' + AUserId.ToString
    + #10'GROUP BY topic_id'
    + #10'ORDER BY date DESC'
    + #10'LIMIT 10'
    + #10') comments ORDER BY date DESC';
  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectComments;
  Data.Open;
  DataToJSON(Data, Result, False);

  for i := 0 to Result.Count-1 do
  begin
    url := '';
    url := 'thread/topic/' + Result.Items[i].Value['topic_id'] + '/'
      + GenerateSlug(Result.Items[i].Value['title']) + '/'
      + '#post-' + Result.Items[i].Value['id'];

    TJSONObject(Result.Items[i]).Add('url',url);
  end;


end;

function TUserModel.AddFromFacebook(AId: Int64; AFirstName, ALastName: String;
  AEmail: String; AExistingUserID: Integer): Boolean;
var
  authUserId: Integer;
begin
  Result := False;
  FCurrentUserName := AFirstName + ALastName;
  authUserId := AExistingUserID;
  if AExistingUserID = 0 then
  begin
    if FindByUserName(FCurrentUserName) then
    begin
      FCurrentUserName += RandomString(3,5);
    end;
    Close;//TODO: change to reset
    Value['username'] := FCurrentUserName;
    Value['email'] := AEmail;
    Value['regdate'] := DateTimeToUnix(Now);
    Value['lastvisit'] := DateTimeToUnix(Now);
    if Save() then
    begin
      authUserId := LastInsertID;
    end;
  end;

  if authUserId > 0 then
  begin
    QueryExec('INSERT INTO user_mapping (type_id, user_id, ref_id, email, date)'
      + #10'VALUES'
      + #10'(1,'+authUserId.ToString+','+AId.ToString+', "'+AEmail+'", NOW())'
    );
    Result := True;
  end;

end;

function TUserModel.AddMapping(ATypeId, AUserId: Integer; AReferenceId: String;
  AEmail: String): boolean;
begin
  QueryExec('INSERT INTO user_mapping (type_id, user_id, ref_id, email, date)'
    + #10'VALUES'
    + #10'('+ATypeId.ToString+','+AUserId.ToString+',"'+AReferenceId+'", "'+AEmail+'", NOW())'
  );
  Result := True;
end;

function TUserModel.IsAdministrator(AUserId: Integer): Boolean;
begin
  Result := False;
  if Select('level').Where('uid='+AUserId.ToString).Open() then
  begin
    if RecordCount = 0 then
      Exit;
    if Value['level'] = 1 then
      Result := True;
  end;
end;

end.

