unit topic_post_model;

{$mode objfpc}{$H+}

interface

uses
  common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type

  { TTopicPostModel }

  TTopicPostModel = class(TSimpleModel)
  private
    FPostId: Integer;
  public
    constructor Create(const DefaultTableName: string = '');

    property PostId: Integer read FPostId;
    function Add(ATopicId, AForumId, APosterId: Integer; AMessage: String): Boolean;
  end;

implementation

uses topic_post_text_model;

constructor TTopicPostModel.Create(const DefaultTableName: string = '');
begin
  inherited Create( 'phpbb_posts');
  primaryKey := 'post_id';
end;

function TTopicPostModel.Add(ATopicId, AForumId, APosterId: Integer;
  AMessage: String): Boolean;
begin
  New;
  Value['topic_id'] := ATopicId;
  Value['forum_id'] := AForumId;
  Value['poster_id'] := APosterId;
  Value['post_time'] := DateTimeToUnix(Now);
  Result := Save();
  if Result then
  begin
    FPostId := LastInsertID;
    with TTopicPostTextModel.Create() do
    begin
      Value['post_id'] := FPostId;
      Value['post_text'] := AMessage;
      Save;
      Free;
    end;
  end;
end;

end.

