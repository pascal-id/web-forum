unit article_detail_controller;

{$mode objfpc}{$H+}

interface

uses
  news_model,
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs,
  fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
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
  if not FNews.Detail(articleId, previewOnly) then
    Redirect('/news/');

  title := FNews['title'];
  dt := FNews['date'];
  s := '2019-11-10 10:11:00';
  if dt < s.AsDateTime then
    title := 'Arsip: ' + title;
  ThemeUtil.Assign('$Title', title);
  ThemeUtil.Assign('$Obsolete', FNews['obsolete']);


  ThemeUtil.Assign('$Date', dt.HumanReadable);

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  //ThemeUtil.TrimWhiteSpace := False;
  Response.Content := ThemeUtil.Render();
  FNews.AddHit(articleId);
end;

// POST Method Handler
procedure TArticleDetailController.Post;
begin
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



