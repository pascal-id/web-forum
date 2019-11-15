unit forum_model;

{$mode objfpc}{$H+}

interface

uses
  fpjson, common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type

  { TForumModel }

  TForumModel = class(TSimpleModel)
  private
    function getCategoryId: integer;
    function getCategoryTitle: string;
    function getForumName: string;
  public
    constructor Create(const DefaultTableName: string = '');

    function All: TJSONArray;
    function ListDetail: TJSONArray;
    function ByCategory(ACategoryId: integer): TJSONArray;

    property ForumName: string read getForumName;
    property CategoryId: integer read getCategoryId;
    property CategoryTitle: string read getCategoryTitle;
  end;

implementation

function TForumModel.getCategoryId: integer;
begin
  Result := Value['cat_id'];
end;

function TForumModel.getCategoryTitle: string;
begin
  Result := Value['cat_title'];
end;

function TForumModel.getForumName: string;
begin
  Result := Value['forum_name'];
end;

constructor TForumModel.Create(const DefaultTableName: string = '');
begin
  inherited Create('phpbb_forums');
  primaryKey := 'forum_id';
  FieldPrefix := '';
end;

function TForumModel.All: TJSONArray;
var
  authFilter: string;
begin
  authFilter := 'auth_read=0'; //todo: forum auth view
  AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id', ['cat_title category']);
  if Find(['forum_status=0', authFilter],
    'phpbb_categories.cat_order ASC, forum_order ASC', 0,
    'forum_id, forum_name, forum_desc, forum_topics, forum_last_post_id, phpbb_forums.cat_id'
    ) then
  begin
    Result := AsJsonArray(False);
  end
  else
    Result := TJSONArray.Create;
end;

function TForumModel.ListDetail: TJSONArray;
begin
  AddJoin('phpbb_categories', 'cat_id', 'phpbb_forums.cat_id', ['cat_title']);
  if Find(['forum_status=0','auth_read=0'], 'phpbb_categories.cat_order, phpbb_forums.forum_order', 0,
    'phpbb_categories.cat_id, cat_title, forum_id, forum_name, forum_desc, forum_topics') then
  begin
    Result := AsJsonArray(False);
  end
  else
    Result := TJSONArray.Create;
end;

function TForumModel.ByCategory(ACategoryId: integer): TJSONArray;
begin
  if Find(['cat_id=' + ACategoryId.ToString, 'forum_status=0', 'auth_view=0', 'auth_read=0'],
    'forum_order', 0,
    'forum_id id, forum_name name, forum_desc description, forum_topics, forum_last_post_id')
  then
  begin
    Result := AsJsonArray(False);
  end
  else
    Result := TJSONArray.Create();
end;

end.

