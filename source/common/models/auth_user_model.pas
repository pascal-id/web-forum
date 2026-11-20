unit auth_user_model;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type

  { TAuthUserModel }

  TAuthUserModel = class(TSimpleModel)
  private
  public
    constructor Create(const DefaultTableName: string = '');

    function FindByEmail(const AEmail: string): boolean;
    function isMappingExist(AUserId: integer; AReferenceId: String): boolean;
  end;

implementation

uses common;

constructor TAuthUserModel.Create(const DefaultTableName: string = '');
begin
  inherited Create(DefaultTableName);
end;

function TAuthUserModel.FindByEmail(const AEmail: string): boolean;
begin
  // AEmail berasal dari Graph API / bukan _POST: belum di-escape
  Result := FindFirst(['email="' + mysql_real_escape_string(AEmail) + '"'], '',
    'auid, username, email, md5(email) gravatar, reg_date, activated');
end;

function TAuthUserModel.isMappingExist(AUserId: integer; AReferenceId: String
  ): boolean;
var
  selectMapping: string;
begin
  Result := False;
  selectMapping := 'SELECT * FROM user_mapping WHERE type_id=1 ' +
    #10'AND user_id=' + AUserId.ToString + ' AND ref_id=''' + mysql_real_escape_string(AReferenceId) + '''' +
    #10'ORDER BY date DESC LIMIT 1';
  if Data.Active then
    Data.Close;
  Data.SQL.Text := selectMapping;
  Data.Open;
  if RecordCount > 0 then
    Result := True;
end;

end.

