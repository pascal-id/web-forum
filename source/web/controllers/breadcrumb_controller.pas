unit breadcrumb_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TBreadCrumbItem }

  TBreadCrumbItem = record
    Title: string;
    URL: string;
    Active: Boolean;
    ClassName: string;
    Icon: string;
  end;

  TBreadCrumbList = array of TBreadCrumbItem;

  { TBreadCrumb }

  TBreadCrumb = class
  private
    FBreadCrumbList: TBreadCrumbList;
  public
    destructor Destroy; override;

    function AsHTML: String;
    procedure Add(ATitle, AURL: string; AActive: Boolean = False; AClass: string = 'breadcrumb-item'; AIcon: string = '');
  end;

implementation

{ TBreadCrumb }

destructor TBreadCrumb.Destroy;
begin
  SetLength(FBreadCrumbList,0);
  inherited Destroy;
end;

function TBreadCrumb.AsHTML: String;
var
  i: Integer;
  LClassName: String;
begin
  Result := '';
  for i:=0 to Length(FBreadCrumbList)-1 do
  begin
    if FBreadCrumbList[i].Active then LClassName :='active ' else LClassName := '';
    Result := Result + #10'<li';
    if not FBreadCrumbList[i].ClassName.IsEmpty then
      LClassName := LClassName + FBreadCrumbList[i].ClassName;
    if not LClassName.IsEmpty then
      Result := Result + ' class="'+LClassName+'"';
    Result := Result + '>';
    if FBreadCrumbList[i].Active then
      Result := Result + FBreadCrumbList[i].Title
    else
      Result := Result + '<a href="'+FBreadCrumbList[i].URL+'">'+FBreadCrumbList[i].Title+'</a>';
    Result := Result + '</li>';
  end;
  Result := Result.Trim;
end;

procedure TBreadCrumb.Add(ATitle, AURL: string; AActive: Boolean;
  AClass: string; AIcon: string);
var
  item: TBreadCrumbItem;
begin
  item.Title := ATitle;
  item.URL := AURL;
  item.Active := AActive;
  item.ClassName := AClass;
  item.Icon := AIcon;

  SetLength(FBreadCrumbList,Length(FBreadCrumbList) + 1);
  FBreadCrumbList[High(FBreadCrumbList)] := item;
end;

end.

