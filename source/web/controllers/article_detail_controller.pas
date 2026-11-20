unit article_detail_controller;

{$mode objfpc}{$H+}

interface

uses
  news_model, user_model,
  Classes, SysUtils, html_lib, fastplaz_app, fpjson, json_lib, HTTPDefs,
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

uses theme_controller, common, common_lib, RegExpr, html_sanitizer_lib;

const
  INLINE_CODE_MARK = #1;

function EscapeHTML(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function IsFenceLine(const ALine: string): boolean;
var
  s: string;
begin
  s := TrimLeft(ALine);
  Result := (Copy(s, 1, 3) = '```') or (Copy(s, 1, 3) = '~~~');
end;

// remove fenced code blocks, so code inside them doesn't affect format detection
function StripFencedCode(const AContent: string): string;
var
  lines: TStringList;
  i: integer;
  inCode: boolean;
begin
  Result := '';
  inCode := False;
  lines := TStringList.Create;
  try
    lines.Text := AContent;
    for i := 0 to lines.Count - 1 do
    begin
      if IsFenceLine(lines[i]) then
      begin
        inCode := not inCode;
        Continue;
      end;
      if not inCode then
        Result := Result + lines[i] + #10;
    end;
  finally
    lines.Free;
  end;
end;

// legacy article: already contains HTML tags
function IsHTMLContent(const AContent: string): boolean;
begin
  Result := False;
  with TRegExpr.Create do
  try
    ModifierI := True;
    Expression := '<(p|br|div|span|a|img|b|i|u|strong|em|table|tr|td|ul|ol|li|pre|code|font|h[1-6]|blockquote|hr|center)[\s/>]';
    Result := Exec(StripFencedCode(AContent));
  finally
    Free;
  end;
end;

// markdown syntax: [link](url), ![image](url), # heading, ```code, **bold**
function HasMarkdownSyntax(const AContent: string): boolean;
begin
  Result := False;
  with TRegExpr.Create do
  try
    ModifierM := True;
    Expression := '(!?\[[^\]\n]+\]\([^\)\s]+\))|(^\s*#{1,6}\s+\S)|(^\s*(```|~~~))|(\*\*[^\*\n]+\*\*)';
    Result := Exec(AContent);
  finally
    Free;
  end;
end;

// bare http(s) URL -> link; URLs already inside a tag attribute or link text are skipped
function AutoLinkURL(const AText: string): string;
var
  re: TRegExpr;
  i: integer;
  url, suffix: string;
begin
  Result := '';
  re := TRegExpr.Create('(="|=''|>)?(https?://[^\s<>"'']+)');
  try
    i := 1;
    if re.Exec(AText) then
    repeat
      Result := Result + Copy(AText, i, re.MatchPos[0] - i);
      if re.Match[1] <> '' then
        Result := Result + re.Match[0]
      else
      begin
        url := re.Match[2];
        suffix := '';
        while (url <> '') and (url[Length(url)] in ['.', ',', ';', ':', ')', '!', '?']) do
        begin
          suffix := url[Length(url)] + suffix;
          Delete(url, Length(url), 1);
        end;
        Result := Result + '<a href="' + url + '" target="_blank" >' + url + '</a>' + suffix;
      end;
      i := re.MatchPos[0] + re.MatchLen[0];
    until not re.ExecNext;
    Result := Result + Copy(AText, i, MaxInt);
  finally
    re.Free;
  end;
end;

// inline markdown (bold, italic, link, image, `code`) via MarkdownToHTML
function MarkdownInline(const AText: string): string;
var
  codes: TStringList;
  re: TRegExpr;
  s: string;
  i: integer;
begin
  codes := TStringList.Create;
  re := TRegExpr.Create;
  try
    // protect inline code from the other inline rules
    s := '';
    re.Expression := '`([^`]+)`';
    Result := AText;
    if re.Exec(Result) then
    begin
      i := 1;
      repeat
        s := s + Copy(Result, i, re.MatchPos[0] - i)
          + INLINE_CODE_MARK + IntToStr(codes.Count) + INLINE_CODE_MARK;
        codes.Add(re.Match[1]);
        i := re.MatchPos[0] + re.MatchLen[0];
      until not re.ExecNext;
      Result := s + Copy(Result, i, MaxInt);
    end;

    Result := MarkdownToHTML(Result);
    Result := AutoLinkURL(Result);

    for i := codes.Count - 1 downto 0 do
      Result := StringReplace(Result,
        INLINE_CODE_MARK + IntToStr(i) + INLINE_CODE_MARK,
        '<code>' + EscapeHTML(codes[i]) + '</code>', [rfReplaceAll]);
    // MarkdownToHTML adds a space after </b>: "<b>x</b> ." -> "<b>x</b>."
    Result := ReplaceRegExpr('(</b>|</i>) +([\.,;:!\?\)])', Result, '$1$2', True);
    Result := Trim(Result);
  finally
    re.Free;
    codes.Free;
  end;
end;

function MarkdownContentToHTML(const AContent: string): string;
var
  lines: TStringList;
  reHeading, reRule, reBullet, reOrdered, reQuote: TRegExpr;
  i, level: integer;
  line, s, fence, lang, code, paragraph, quote, listTag: string;

  // plain text lines end with <br />, no <p>
  procedure FlushParagraph;
  begin
    if paragraph = '' then
      Exit;
    s := MarkdownInline(paragraph);
    s := StringReplace(s, #10, '<br />'#10, [rfReplaceAll]);
    Result := Result + s + '<br />'#10;
    paragraph := '';
  end;

  procedure FlushQuote;
  begin
    if quote = '' then
      Exit;
    s := MarkdownInline(quote);
    s := StringReplace(s, #10, '<br />'#10, [rfReplaceAll]);
    Result := Result + '<blockquote>' + s + '</blockquote>'#10;
    quote := '';
  end;

  procedure CloseList;
  begin
    if listTag = '' then
      Exit;
    Result := Result + '</' + listTag + '>'#10;
    listTag := '';
  end;

  procedure FlushAll;
  begin
    FlushParagraph;
    FlushQuote;
    CloseList;
  end;

  procedure AddListItem(const ATag, AText: string);
  begin
    FlushParagraph;
    FlushQuote;
    if listTag <> ATag then
    begin
      CloseList;
      listTag := ATag;
      Result := Result + '<' + listTag + '>'#10;
    end;
    Result := Result + '<li>' + MarkdownInline(AText) + '</li>'#10;
  end;

begin
  Result := '';
  paragraph := '';
  quote := '';
  listTag := '';

  lines := TStringList.Create;
  reHeading := TRegExpr.Create('^(#{1,6})\s+(.*?)\s*#*\s*$');
  reRule := TRegExpr.Create('^((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$');
  reBullet := TRegExpr.Create('^\s*[\*\-\+]\s+(.*)$');
  reOrdered := TRegExpr.Create('^\s*\d+[\.\)]\s+(.*)$');
  reQuote := TRegExpr.Create('^\s*>\s?(.*)$');
  try
    lines.Text := AContent;
    i := 0;
    while i < lines.Count do
    begin
      line := TrimRight(lines[i]);

      // fenced code block
      if IsFenceLine(line) then
      begin
        FlushAll;
        s := TrimLeft(line);
        fence := Copy(s, 1, 3);
        lang := Trim(Copy(s, 4, MaxInt));
        code := '';
        Inc(i);
        while (i < lines.Count) and (Copy(TrimLeft(lines[i]), 1, 3) <> fence) do
        begin
          code := code + lines[i] + #10;
          Inc(i);
        end;
        Inc(i); // closing fence
        s := '<pre><code';
        if lang <> '' then
          s := s + ' class="language-' + EscapeHTML(lang) + '"';
        Result := Result + s + '>' + EscapeHTML(TrimRight(code)) + '</code></pre>'#10;
        Continue;
      end;

      if Trim(line) = '' then
      begin
        // blank line after text: one extra <br /> as paragraph spacing
        if paragraph <> '' then
        begin
          FlushParagraph;
          Result := Result + '<br />'#10;
        end;
        // keep the list open: items may be separated by blank lines
        FlushQuote;
      end
      else if reHeading.Exec(Trim(line)) then
      begin
        FlushAll;
        level := Length(reHeading.Match[1]);
        Result := Result + '<h' + IntToStr(level) + '>'
          + MarkdownInline(reHeading.Match[2]) + '</h' + IntToStr(level) + '>'#10;
      end
      else if reRule.Exec(Trim(line)) then
      begin
        FlushAll;
        Result := Result + '<hr />'#10;
      end
      else if reBullet.Exec(line) then
        AddListItem('ul', reBullet.Match[1])
      else if reOrdered.Exec(line) then
        AddListItem('ol', reOrdered.Match[1])
      else if reQuote.Exec(line) then
      begin
        FlushParagraph;
        CloseList;
        if quote <> '' then
          quote := quote + #10;
        quote := quote + reQuote.Match[1];
      end
      else
      begin
        FlushQuote;
        CloseList;
        if paragraph <> '' then
          paragraph := paragraph + #10;
        paragraph := paragraph + line;
      end;

      Inc(i);
    end;
    FlushAll;

    // block elements have their own spacing: drop <br /> around them
    Result := ReplaceRegExpr('(<br />\s*)+(<(h[1-6]|ul|ol|pre|blockquote|hr)[\s>/])',
      Result, '$2', True);
    Result := ReplaceRegExpr('(</(h[1-6]|ul|ol|pre|blockquote)>|<hr />)\s*(<br />\s*)+',
      Result, '$1'#10, True);
    Result := ReplaceRegExpr('(<br />\s*)+$', Result, '', True);
  finally
    reQuote.Free;
    reOrdered.Free;
    reBullet.Free;
    reRule.Free;
    reHeading.Free;
    lines.Free;
  end;
end;

// article content can be markdown or legacy (HTML/BBCode)
function ArticleContentToHTML(const AContent: string): string;
begin
  Result := FormatTextLikeForum(AContent);
  // legacy HTML article, unless it also contains markdown syntax
  if IsHTMLContent(Result) and not HasMarkdownSyntax(Result) then
    Exit;
  // markdown mixed with <br>: treat <br> as line break,
  // a <br> next to a newline is the same line break
  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll]);
  Result := ReplaceRegExpr('(?i)\n[ \t]*<br\s*/?>', Result, #10, False);
  Result := ReplaceRegExpr('(?i)<br\s*/?>[ \t]*\n', Result, #10, False);
  Result := ReplaceRegExpr('(?i)<br\s*/?>', Result, #10, False);
  Result := MarkdownContentToHTML(Result);
  if Result <> '' then
    Result := '<div class="md-content">' + Result + '</div>';
end;

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
  begin
    Redirect('/news/');
    Exit;
  end;

  DataBaseInit;
  QueryExec('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,''ONLY_FULL_GROUP_BY'',''''))');

  if not FNews.Detail(articleId, previewOnly) then
  begin
    Redirect('/news/');
    Exit;
  end;

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
  begin
    OutputJson(404, ERR_NOT_PERMITTED);
    Exit;
  end;
  if not IsValidCSRFToken then
  begin
    OutputJson(403, ERR_CSRF_INVALID);
    Exit;
  end;

  ArticleId := _POST['id'].AsInteger;
  if ArticleId = 0 then
  begin
    OutputJson(404, ERR_DATA_NOT_FOUND);
    Exit;
  end;

  homeText := UrlDecode(_POST['homeText']);
  bodyText := UrlDecode(_POST['bodyText']);
  if (homeText.IsEmpty AND bodyText.IsEmpty) then
  begin
    OutputJson(404, ERR_INVALID_PARAMETER);
    Exit;
  end;

  DataBaseInit;
  if not FNews.Detail(articleId, True) then
  begin
    OutputJson(404, ERR_DATA_NOT_FOUND);
    Exit;
  end;

  //check permission
  if UserSession.UserName <> FNews['contributor'] then
  begin
    with TUserModel.Create() do
    begin
      if not IsAdministrator(UserSession.UserId) then
      begin
        Free;
        OutputJson(400, ERR_NOT_PERMITTED);
        Exit;
      end;
      Free;
    end;
  end;

  if not homeText.IsEmpty then
    FNews['hometext'] := homeText;
  if not bodyText.IsEmpty then
    FNews['bodytext'] := bodyText;
  if not FNews.Save('nid='+ArticleId.ToString) then
  begin
    OutputJson(404, ARTICLE_SAVE_ERROR);
    Exit;
  end;

  OutputJson(200, OK);
end;

function TArticleDetailController.Tag_MainContent_Handler(const TagName: string;
  Params: TStringList): string;
var
  homeText, bodyText, ogImage, ogDefaultImage, ogDescription: string;
begin
  // konten artikel buatan user: sanitasi HTML hasil render (anti XSS)
  homeText := SafeHTML(ArticleContentToHTML(FNews['hometext']));
  bodyText := SafeHTML(ArticleContentToHTML(FNews['bodytext']));
  ThemeUtil.Assign('$HomeText', homeText);
  ThemeUtil.Assign('$BodyText', bodyText);
  ThemeUtil.AssignVar['$Article'] := @FNews.Data;
  Result := ThemeUtil.RenderFromContent(nil, '', 'modules/article/detail.html');
  Result := ReplaceFromLegacy(Result);
  Result := Result.Replace('\''', '''');

  // image and description come from the article content only
  ogDefaultImage := BaseURL + ARTICLE_DEFAULT_OGIMAGE;
  ogImage := GetOpenGraphImage(ReplaceFromLegacy(homeText + bodyText), ogDefaultImage);
  ogDescription := GetOpenGraphDescription(homeText);
  if ogDescription = '' then
    ogDescription := GetOpenGraphDescription(bodyText);

  SetOpenGraph(FNews['title'], ogImage,
    BaseURL + 'news/' + articleId.ToString + '/' + FNews['slug'],
    ogDescription, 'article', ogImage <> ogDefaultImage);
end;


end.



