unit article_new_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, HTTPDefs, 
    fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers;

type
  TArticleNewController = class(TMyCustomController)
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

uses theme_controller, common, common_lib, news_model;

constructor TArticleNewController.CreateNew(AOwner: TComponent;
  CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TArticleNewController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TArticleNewController.BeforeRequestHandler(Sender: TObject;
  ARequest: TRequest);
begin
end;

// GET Method Handler
procedure TArticleNewController.Get;
var
  s: String;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  if UserSession.IsExpired then
  begin
    die('login dulu..');
  end;

  s := IncDay(Now, 3).Format('dd-mm-yyyy hh:nn');
  ThemeUtil.Assign('$Title', 'New Article');
  ThemeUtil.Assign('$Date', s);

  ThemeUtil.AddCSS(BaseURL + 'themes/PascalIndonesia/plugins/jquery-ui/jquery-ui.min.css');
  ThemeUtil.AddCSS(BaseURL + 'themes/PascalIndonesia/plugins/summernote/summernote-bs4.css');
  ThemeUtil.AddJS(BaseURL + 'themes/PascalIndonesia/plugins/summernote/summernote-bs4.min.js');
  ThemeUtil.AddCSS(BaseURL + 'themes/PascalIndonesia/plugins/datetimepicker/build/jquery.datetimepicker.min.css');
  ThemeUtil.AddJS(BaseURL + 'themes/PascalIndonesia/plugins/datetimepicker/build/jquery.datetimepicker.full.min.js');

  //ThemeUtil.AddCSS(BaseURL + 'themes/PascalIndonesia/plugins/daterangepicker/daterangepicker.css');
  //ThemeUtil.AddJS(BaseURL + 'themes/PascalIndonesia/plugins/daterangepicker/daterangepicker.js');

  ThemeUtil.AddCSS(BaseURL + 'modules/article/css/style.css?_=1');

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TArticleNewController.Post;
var
  articleId: Integer;
  token: String;
  title, homeText, bodyText, date, category: String;
  dt: TDateTime;
  json: TJSONUtil;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  token := Header['token'];
  //if token.IsEmpty then
  //  OutputJson(500, ERR_NOT_PERMITTED);

  title := _POST['title'];
  date := _POST['date'];

  dt := ScanDateTime('DD-MM-YYYY hh:nn', date);
  homeText := UrlDecode(_POST['hometext']);
  bodyText := UrlDecode(_POST['bodytext']);
  category := _POST['category'];

  if title.IsEmpty or homeText.IsEmpty or bodyText.IsEmpty or date.IsEmpty then
    OutputJson(400, ERR_INVALID_PARAMETER);

  DataBaseInit;
  QueryExec('SET CHARACTER SET utf8;');
  articleId := 0;
  with TNewsModel.Create() do
  begin
    if not Add(UserSession.UserName, title, homeText, bodyText, dt) then
    begin
      Free;
      OutputJson(400, ARTICLE_SAVE_ERROR);
    end;
    articleId := LastInsertID;
    Free;
  end;

  with TJSONUtil.Create do
  begin
    Value['code'] := Int64(200);
    Value['id'] := articleId;
    Value['url'] := BaseURL + 'news/' + articleId.ToString + '/'
      + GenerateSlug(title) + '?preview=1';

    Response.ContentType := 'application/json';
    Response.Content := AsJSON;
    Free;
  end;
end;

function TArticleNewController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/article/new.html');
end;


end.

