unit auth_token_model;

{$mode objfpc}{$H+}

interface

uses
  common, fpcgi,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type

  { TAuthTokenModel }

  TAuthTokenModel = class(TSimpleModel)
  private
    FClientId: integer;
    FExpiredDate: TDateTime;
  public
    constructor Create(const DefaultTableName: string = '');

    function AddToken(AToken: string; AUserId: integer;
      AExpired: integer = 24 * 7): boolean;
    function IsValid(AToken: string): boolean;

    property ClientId: integer read FClientId write FClientId;
    property ExpiredDate: TDateTime read FExpiredDate write FExpiredDate;
  end;

implementation

constructor TAuthTokenModel.Create(const DefaultTableName: string = '');
begin
  inherited Create(DefaultTableName);

  FClientId := 0;
end;

function TAuthTokenModel.AddToken(AToken: string; AUserId: integer;
  AExpired: integer): boolean;
begin
  Result := False;
  FExpiredDate := now.IncHour(AExpired);
  Value['client_id'] := ClientId;
  Value['token'] := AToken;
  Value['user_id'] := AUserId;
  Value['ip_addr'] := Application.Request.RemoteAddress;
  Value['expired_date'] := FExpiredDate;
  Value['status_id'] := 0;
  Result := Save();
end;

function TAuthTokenModel.IsValid(AToken: string): boolean;
begin
  Result := False;
  AddJoin('auth_users', 'auid', 'user_id',['username', 'email']);
  if Find(['status_id=0', 'token="' + AToken + '"',
    'expired_date > "'+Now.AsString+'"'],
    'expired_date DESC',
    1,
    'atid, token, user_id, expired_date, md5(auth_users.email) gravatar'
  ) then
  begin
    FExpiredDate := Value['expired_date'];
    if RecordCount > 0 then
      Result := True;
  end;
end;

end.

