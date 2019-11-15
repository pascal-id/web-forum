unit topic_post_text_model;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TTopicPostTextModel = class(TSimpleModel)
  private
  public
    constructor Create(const DefaultTableName: string = '');
  end;

implementation

constructor TTopicPostTextModel.Create(const DefaultTableName: string = '');
begin
  inherited Create( 'phpbb_posts_text');
  primaryKey := 'post_id';
end;

end.

