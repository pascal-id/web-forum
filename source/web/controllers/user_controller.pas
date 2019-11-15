unit user_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TUserController = class(TMyCustomController)
  private
    function Tag_MainContent_Handler(const TagName: string; Params: TStringList
      ): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses theme_controller, common;

constructor TUserController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TUserController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TUserController.BeforeRequestHandler(Sender: TObject; 
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TUserController.Get;
begin
  Redirect('/');
  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TUserController.Post;
begin
end;

function TUserController.Tag_MainContent_Handler(const TagName: string; 
  Params: TStringList): string;
begin

  // your code here
  Result:=h3('Hello "User" Module ... FastPlaz !');

end;


end.

