unit news_model;

{$mode objfpc}{$H+}

interface

uses
  common, common_lib,
  Classes, SysUtils, database_lib, string_helpers, dateutils, datetime_helpers,
  array_helpers;

{$include ../../common/common.inc}

type

  { TNewsModel }

  TNewsModel = class(TSimpleModel)
  private
  public
    constructor Create(const DefaultTableName: string = '');

    function Add(AContributor: String; ATitle, AHomeText, ABodyText: String; ADate: TDateTime): Boolean;
    function Last(ALimit: integer = 0; AFull: boolean = False): boolean;
    function Random(ALimit: integer = 0; AFull: boolean = False): boolean;
    function Detail(ANewsID: integer; AShowEverything: Boolean = False): boolean;
    function SearchTitle(AKeyword: String; ALimit: Integer = NEWS_DEFAULT_LIMIT;
      AShowEverything: Boolean = False): Boolean;
    procedure AddHit(ANewsID: Integer);
  end;

implementation

constructor TNewsModel.Create(const DefaultTableName: string = '');
begin
  inherited Create('news');
  primaryKey := 'nid';
end;

function TNewsModel.Add(AContributor: String; ATitle, AHomeText,
  ABodyText: String; ADate: TDateTime): Boolean;
begin
  Result := False;
  Value['title'] := ATitle;
  Value['urltitle'] := GenerateSlug(ATitle);
  Value['hometext'] := AHomeText;
  Value['bodytext'] := ABodyText;
  Value['contributor'] := AContributor;
  Value['`from`'] := ADate;
  Value['cr_date'] := Now();
  Value['counter'] := 0;
  Value['status_id'] := 2;
  Value['published_status'] := 2;
  Value['archived'] := 1;
  Result := Save();
  //TODO: add to category mapping: category_mapobj
end;

function TNewsModel.Last(ALimit: integer; AFull: boolean): boolean;
var
  fieldList: string;
begin
  fieldList := 'nid id, urltitle slug, title, hometext, `from` date, unix_timestamp(`from`) timestamp, contributor, counter, archived';
  if AFull then
    fieldList := fieldList + ', bodytext';

  AddLeftJoin('categories_mapobj', 'cmo_obj_id', 'nid  AND cmo_reg_id=2', ['cmo_category_id category_id']);
  AddLeftJoin('categories_category', 'cat_id', 'categories_mapobj.cmo_category_id', ['cat_name category_name']);
  Result := Find(['status_id=0', 'published_status=0', 'hideonindex=0', '`from`<"'+Now.AsString+'"'],
    '`from` DESC',
    ALimit, fieldList);
end;

function TNewsModel.Random(ALimit: integer; AFull: boolean): boolean;
var
  fieldList: string;
begin
  fieldList := 'nid id, urltitle slug, title, hometext, `from` date, unix_timestamp(`from`) timestamp , contributor, counter, archived';
  if AFull then
    fieldList := fieldList + ', bodytext';

  AddLeftJoin('categories_mapobj', 'cmo_obj_id', 'nid  AND cmo_reg_id=2', ['cmo_category_id category_id']);
  AddLeftJoin('categories_category', 'cat_id', 'categories_mapobj.cmo_category_id', ['cat_name category_name']);
  Result := Find(['status_id=0', 'published_status=0', 'hideonindex=0', '`from`<"'+Now.AsString+'"'],
    'RAND()',
    ALimit, fieldList);
end;

function TNewsModel.Detail(ANewsID: integer; AShowEverything: Boolean): boolean;
var
  fieldList: string;
  whereAsArray: TStringArray;
begin
  fieldList := 'nid, urltitle slug, title, hometext, bodytext, notes, `from` date, unix_timestamp(`from`) timestamp , contributor, counter, obsolete, archived';
  AddLeftJoin('categories_mapobj', 'cmo_obj_id', 'nid', ['cmo_category_id category_id']);
  AddLeftJoin('categories_category', 'cat_id', 'categories_mapobj.cmo_category_id', ['cat_name category_name']);

  whereAsArray.Add('nid=' + i2s(ANewsID));
  if not AShowEverything then
  begin
    whereAsArray.Add('`from`<"'+Now.AsString+'"');
    whereAsArray.Add('status_id=0');
    whereAsArray.Add('published_status=0');
  end;
  Result := FindFirst(whereAsArray, '', fieldList);
end;

function TNewsModel.SearchTitle(AKeyword: String; ALimit: Integer;
  AShowEverything: Boolean): Boolean;
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
  if AShowEverything then
  begin
    whereQuery := '(published_status=0 AND status_id=0 AND (';
  end else
  begin
    whereQuery := '(published_status=0 AND status_id=0 AND `from` < NOW() AND (';
  end;
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
      whereQuery +=  ' ' + prefixWhere + '  title LIKE ''%'+s+'%'''
    end
    else
    begin
      if i > 0 then prefixWhere := ' OR ';
      whereQuery +=  ' ' + prefixWhere + ' title LIKE ''%'+keywordList[i]+'%''';
    end;
  end;
  whereQuery += '))';

  if Data.Active then
    Data.Close;
  Data.SQL.Text := 'SELECT nid, title, hometext, contributor, `from` date '
    + #10'FROM news'
    + #10'WHERE ' + whereQuery
    + #10'LIMIT ' + ALimit.ToString;
  Data.Open;
  Result := True;
end;

procedure TNewsModel.AddHit(ANewsID: Integer);
begin
  if ANewsID = 0 then
    Exit;
  QueryExec('UPDATE news SET counter=counter+1 WHERE nid='+ANewsID.ToString+';');
end;

end.

