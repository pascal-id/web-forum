unit category_model;

{$mode objfpc}{$H+}

interface

uses
  common,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers;

type

  { TCategoryModel }

  TCategoryModel = class(TSimpleModel)
  private
    function getCategoryTitle: String;
  public
    constructor Create(const DefaultTableName: string = '');

    function IsExist(AId: Integer): Boolean;
    property CategoryTitle: String read getCategoryTitle;
  end;

implementation

function TCategoryModel.getCategoryTitle: String;
begin
  Result := Value['cat_title'];
end;

constructor TCategoryModel.Create(const DefaultTableName: string = '');
begin
  inherited Create( 'phpbb_categories');
  primaryKey := 'cat_id';
end;

function TCategoryModel.IsExist(AId: Integer): Boolean;
begin
  Result := FindFirst(['cat_id='+AId.ToString]);
end;

end.

