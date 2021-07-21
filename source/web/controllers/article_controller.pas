unit article_controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, html_lib, fpcgi, fpjson, json_lib, datetime_lib,
  HTTPDefs, fastplaz_handler, database_lib, string_helpers, dateutils, datetime_helpers,
  json_helpers;

type

  { TArticleController }

  TArticleController = class(TMyCustomController)
  private
    function Tag_MainContent_Handler(const TagName: string;
      Params: TStringList): string;
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
    function ViewAsList(AContent: TJSONArray; ADetail: Boolean = True; AIsRandom: Boolean = False): string;
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;

    // Block Handler
    procedure DoBlockController(Sender: TObject; FunctionName: string;
      Parameter: TStrings; var ResponseString: string);
  end;

implementation

uses theme_controller, common, news_model, common_lib;

constructor TArticleController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
  OnBlockController := @DoBlockController;
end;

destructor TArticleController.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TArticleController.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
end;

function TArticleController.ViewAsList(AContent: TJSONArray; ADetail: Boolean;
  AIsRandom: Boolean): string;
var
  i, n: Integer;
  s, articleUrl: String;
  dt: TDateTime;
  isArchiveActive: Boolean;
  archivedTopic: Integer;
begin
  isArchiveActive := False;
  Result := '<ul>';
  for i := 0 to AContent.Count - 1 do
  begin
    s := AContent.Items[i].ValueOfName('date').AsString;
    dt := ScanDateTime('YYYY-MM-DD hh:nn:ss', s);
    archivedTopic := AContent.Items[i].ValueOfName('archived').AsInteger;
    if not AIsRandom then
    begin
      if archivedTopic=0 then
      begin
        if not isArchiveActive then
        begin
          isArchiveActive := True;
          Result += '<li class="archive"><span class="archive">Archive</span></li>';
        end;
      end;
    end;
    articleUrl := BaseURL + 'news/' + AContent.Items[i].ValueOfName(
      'id').AsString + '/' + AContent.Items[i].ValueOfName('slug').AsString;
    Result += '<li>';
    Result += '<a href="' + articleUrl + '">';
    Result += AContent.Items[i].ValueOfName('title').AsString;
    Result += '</a>';
    if ADetail then
    begin
      Result += '<br /><span class="small">';
      //Result += 'post ';
      //Result += DateTimeHuman(dt);
      //Result += ' in ' + AContent.Items[i].ValueOfName('category_name').AsString;
      Result += '</span>';
    end;
    Result += '</li>';
  end;
  Result += '</ul>';

end;

// GET Method Handler
procedure TArticleController.Get;
begin
  GetUserSessionInfo;
  SetThemeParameter;

  DataBaseInit;
  QueryExec('SET CHARACTER SET utf8;');
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  ThemeUtil.Assign('$Title', 'Article');
  ThemeUtil.AddCSS(BaseURL + 'modules/article/css/style.css');

  // Open Graph
  SetOpenGraph('Article',
    GetOpenGraphImage('', BaseURL + ARTICLE_DEFAULT_OGIMAGE),
    BaseURL + 'news/');

  Tags['maincontent'] := @Tag_MainContent_Handler; //<<-- tag maincontent handler
  Response.Content := ThemeUtil.Render();
end;

// POST Method Handler
procedure TArticleController.Post;
begin
end;

procedure TArticleController.DoBlockController(Sender: TObject;
  FunctionName: string; Parameter: TStrings; var ResponseString: string);
var
  limitView: integer;
  articleAsArray: TJSONArray;
begin
  limitView := Parameter.Values['limit'].AsInteger;
  if limitView = 0 then limitView := 10;;
  case FunctionName of
    'lastarticle':
    begin
      with TNewsModel.Create() do
      begin
        Last(limitView);
        articleAsArray := AsJsonArray();
        ResponseString := ViewAsList( articleAsArray);
        Free;
      end;
    end;
    'randomarticle':
    begin
      with TNewsModel.Create() do
      begin
        Random(limitView);
        articleAsArray := AsJsonArray();
        ResponseString := ViewAsList( articleAsArray, False, True);
        Free;
      end;
    end;
  end;

end;

function TArticleController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
begin
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/article/home.html');
end;

end.

