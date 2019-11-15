unit profile_controller;

{$mode objfpc}{$H+}

interface

uses
  user_model,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TProfileController = class(TMyCustomController)
  private
    FUser: TUserModel;
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

uses theme_controller, common, common_lib;

constructor TProfileController.CreateNew(AOwner: TComponent; CreateMode: integer
  );
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FUser := TUserModel.Create();
end;

destructor TProfileController.Destroy;
begin
  FUser.Free;
  inherited Destroy;
end;

// Init First
procedure TProfileController.BeforeRequestHandler(Sender: TObject; 
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TProfileController.Get;
var
  userName: String;
  regDateAsInteger, lastVisitAsInteger: Integer;
  timelineAsArray: TJSONArray;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  userName := _GET['$1'];
  userName := ExcludeTrailingBackslash(userName);
  if userName.IsEmpty then
    Redirect('/');

  DataBaseInit();
  QueryExec('SET CHARACTER SET utf8;');

  if not FUser.FindByUserName(userName) then
    Redirect('/', 'User not found');

  regDateAsInteger := FUser['regdate'];
  lastVisitAsInteger := FUser['lastvisit'];
  ThemeUtil.Assign('$UserName', FUser['username']);
  ThemeUtil.Assign('$Title', FUser['username'] + ' profile');
  ThemeUtil.Assign('$Gravatar', FUser['gravatar']);
  ThemeUtil.Assign('$RegDate', regDateAsInteger.ToString);
  ThemeUtil.Assign('$StoryNum', FUser['storynum']);
  ThemeUtil.Assign('$LastVisit', lastVisitAsInteger.ToString);

  ThemeUtil.Assign('$ArticleCount', FUser.ArticleCount.ToString);
  ThemeUtil.Assign('$PostCount', FUser.PostCount.ToString);
  ThemeUtil.Assign('$CommentCount', FUser.CommentCount.ToString);
  ThemeUtil.Assign('$Signature', FUser['signature']);

  ThemeUtil.Assign('$UserLevel', FUser['level']);
  ThemeUtil.Assign('$UserRank', FUser['rank']);
  ThemeUtil.Assign('$UserFrom', FUser['user_from']);
  ThemeUtil.Assign('$UserRankName', FUser.RankName);

  SetOpenGraph( 'User Profile: ' + FUser['username'],
    'https://img.pascal-id.org/' + 'profile-image/'+FUser['gravatar']+'.jpg',
    BaseURL + 'profile/'+FUser['username']);

  //timelineAsArray := FUser.TimeLine(4, FUser['username']);
  //todo: generate timeline

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TProfileController.Post;
begin
end;

function TProfileController.Tag_MainContent_Handler(const TagName: string; 
  Params: TStringList): string;
begin
  ThemeUtil.AssignVar['$User'] := @FUser.Data;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/user/profile.html');
end;


end.

