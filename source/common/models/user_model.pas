unit user_model;

{$mode objfpc}{$H+}

interface

uses
  fpjson, common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

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
    function TimeLine(AUserId: integer; AUserName: String): TJSONArray;
    function AddFromFacebook(AId: Int64; AFirstName, ALastName: String; AEmail: String; AExistingUserID: Integer = 0): Boolean;
    function AddMapping(ATypeId, AUserId: Integer; AReferenceId: String; AEmail: String): boolean;

    property CurrentUserName: String read FCurrentUserName;
    property RankName: String read getRankName;
    property LevelName: String read getLevelName;
    property ArticleCount: Integer read getArticleCount;
    property PostCount: Integer read getPostCount;
    property CommentCount: Integer read getCommentCount;
  end;

implementation

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
  Result := FindFirst(['username="'+AUserName+'"', 'activated=0'], '',
    'uid, username, email, md5(email) gravatar, regdate, storynum, lastvisit, '
    + 'post_count, signature, level, rank, user_from');
end;

function TUserModel.FindByEmail(const AEmail: String): Boolean;
begin
  Result := FindFirst(['email="'+AEmail+'"'], '',
    'uid, username, email, md5(email) gravatar, regdate, storynum, lastvisit, '
    + 'post_count, signature, level, rank, user_from');
end;

function TUserModel.TimeLine(AUserId: integer; AUserName: String): TJSONArray;
var
  selectTimeLine: String;
begin
  Result := TJSONArray.Create;
  if AUserId = 0 then
    exit;

  //if not FindFirst(['uid='+AUserId.ToString]) then
  //  Exit;
  //userName := Data['username'];

  selectTimeLine := 'SELECT * FROM ('
    + #10'SELECT ''topic'' post_type, topic_id id, topic_title title, topic_time date FROM phpbb_topics'
    + #10'WHERE topic_status=0 AND topic_poster=' + AUserId.ToString
    + #10'UNION ALL'
    + #10'SELECT ''news'' post_type, nid id, title, unix_timestamp(`from`) date FROM news'
    + #10'WHERE contributor="'+AUserName+'"'
    + #10'ORDER BY date desc'
    + #10'LIMIT 10'
    + #10') AS timeline ORDER BY date LIMIT 10';

  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectTimeLine;
  Data.Open;
  DataToJSON(Data, Result, False);
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

end.

