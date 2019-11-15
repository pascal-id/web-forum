unit obsolete_model;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TObsoleteModel = class(TSimpleModel)
  private
  public
    constructor Create(const DefaultTableName: string = '');
  end;

implementation

constructor TObsoleteModel.Create(const DefaultTableName: string = '');
begin
  inherited Create( DefaultTableName);
  primaryKey := 'oid';
end;

end.

