unit article_detail_controller;

{$mode objfpc}{$H+}

interface

uses
  news_model, user_model,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

{$include ../../common/common.inc}

type

  { TArticleDetailController }

  TArticleDetailController = class(TMyCustomController)
  private
    ArticleId: integer;
    FNews: TNewsModel;
    function Tag_MainContent_Handler(const TagName: string;
      Params: TStringList): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
    procedure Put; override;
  end;

implementation

uses theme_controller, common, common_lib;

constructor TArticleDetailController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  FNews := TNewsModel.Create();
end;

destructor TArticleDetailController.Destroy;
begin
  FNews.Free;
  inherited Destroy;
end;

// Init First
procedure TArticleDetailController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TArticleDetailController.Get;
var
  dt: TDateTime;
  previewOnly: Boolean;
  s, title: String;
begin
  previewOnly := False;
  GetUserSessionInfo;
  SetThemeParameter;

  if _GET['preview'] = '1' then
  begin
    previewOnly := True;
    //TODO: check permission to show preview
  end;

  articleId := _GET['$1'].AsInteger;
  if articleId = 0 then
    Redirect('/news/');

  DataBaseInit;
  QueryExec('SET CHARACTER SET utf8mb4;');
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  if not FNews.Detail(articleId, previewOnly) then
    Redirect('/news/');

  if not UserSession.IsExpired then
  begin
    if UserSession.UserName = FNews['contributor'] then
      ThemeUtil.Assign(TAG_USER_CAN_EDIT, '0')
    else
    begin
      with TUserModel.Create() do
      begin
        if IsAdministrator(UserSession.UserId) then
        begin
          ThemeUtil.Assign(TAG_USER_CAN_EDIT, '0');
        end;
        Free;
      end;

    end;
  end;

  title := FNews['title'];
  dt := FNews['date'];
  s := '2019-11-10 10:11:00';
  if dt < s.AsDateTime then
    title := 'Arsip: ' + title;
  ThemeUtil.Assign('$Title', title);
  ThemeUtil.Assign('$Obsolete', FNews['obsolete']);


  ThemeUtil.Assign('$Date', dt.HumanReadable);
  ThemeUtil.Assign('$ArticleUrl', BaseURL + 'news/' + articleId.ToString + '/' + String(FNews['slug']));

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  //ThemeUtil.TrimWhiteSpace := False;
  Response.Content := ThemeUtil.Render();
  FNews.AddHit(articleId);
end;

// POST Method Handler
procedure TArticleDetailController.Post;
begin
end;

procedure TArticleDetailController.Put;
var
  homeText, bodyText: String;
begin
  GetUserSessionInfo;
  SetThemeParameter;
  if UserSession.IsExpired then
    OutputJson(404, ERR_NOT_PERMITTED);

  ArticleId := _POST['id'].AsInteger;
  if ArticleId = 0 then
    OutputJson(404, ERR_DATA_NOT_FOUND);

  homeText := UrlDecode(_POST['homeText']);
  bodyText := UrlDecode(_POST['bodyText']);
  if (homeText.IsEmpty AND bodyText.IsEmpty) then
    OutputJson(404, ERR_INVALID_PARAMETER);

  DataBaseInit;
  QueryExec('SET CHARACTER SET utf8mb4;');
  if not FNews.Detail(articleId, True) then
    OutputJson(404, ERR_DATA_NOT_FOUND);

  //check permission
  if UserSession.UserName <> FNews['contributor'] then
  begin
    with TUserModel.Create() do
    begin
      if not IsAdministrator(UserSession.UserId) then
      begin
        Free;
        OutputJson(400, ERR_NOT_PERMITTED);
      end;
      Free;
    end;
  end;

  if not homeText.IsEmpty then
    FNews['hometext'] := homeText;
  if not bodyText.IsEmpty then
    FNews['bodytext'] := bodyText;
  if not FNews.Save('nid='+ArticleId.ToString) then
    OutputJson(404, ARTICLE_SAVE_ERROR);

  OutputJson(200, OK);
end;

function TArticleDetailController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
var
  s: String;
begin
  //s := FNews['bodytext'];
  //s := MarkdownToHTML(s);
  //die(s);
  ThemeUtil.AssignVar['$Article'] := @FNews.Data;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/article/detail.html');
  Result := ReplaceFromLegacy(Result);
  Result := Result.Replace('\''', '''');

  SetOpenGraph(FNews['title'],
    GetOpenGraphImage(Result, BaseURL + ARTICLE_DEFAULT_OGIMAGE),
    BaseURL + 'news/' + articleId.ToString + '/' + FNews['slug']);

end;


end.



