unit sitemap_controller;

{
  Dynamic sitemap.xml (https://www.sitemaps.org/protocol.html)

  Lists the static pages, every forum, every visible forum topic and every
  published news article, generated from the database on each request.
  Forums that need a permission to view or read (auth_view/auth_read <> 0)
  and their topics are left out.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fastplaz_handler, database_lib, dateutils, HTTPDefs;

type

  { TSitemapController }

  TSitemapController = class(TMyCustomController)
  private
    FXml: TStringList;
    procedure AddUrl(const ALoc: string; ALastMod: TDateTime;
      const AChangeFreq, APriority: string);
    procedure AddStaticPages;
    procedure AddForums;
    procedure AddTopics;
    procedure AddNews;
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
  end;

implementation

uses common_lib;

function XmlEscape(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

constructor TSitemapController.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  FXml := TStringList.Create;
end;

destructor TSitemapController.Destroy;
begin
  FXml.Free;
  inherited Destroy;
end;

procedure TSitemapController.AddUrl(const ALoc: string; ALastMod: TDateTime;
  const AChangeFreq, APriority: string);
begin
  FXml.Add('  <url>');
  FXml.Add('    <loc>' + XmlEscape(ALoc) + '</loc>');
  if ALastMod > 0 then
    FXml.Add('    <lastmod>' + FormatDateTime('yyyy-mm-dd', ALastMod) + '</lastmod>');
  if AChangeFreq <> '' then
    FXml.Add('    <changefreq>' + AChangeFreq + '</changefreq>');
  if APriority <> '' then
    FXml.Add('    <priority>' + APriority + '</priority>');
  FXml.Add('  </url>');
end;

procedure TSitemapController.AddStaticPages;
begin
  AddUrl(BaseURL, 0, 'daily', '1.0');
  AddUrl(BaseURL + 'forum/', 0, 'daily', '0.9');
  AddUrl(BaseURL + 'news/', 0, 'daily', '0.9');
end;

procedure TSitemapController.AddForums;
begin
  with TSimpleModel.Create('phpbb_forums') do
  begin
    try
      Data.SQL.Text := 'SELECT forum_id, forum_name'
        + #10'FROM phpbb_forums'
        + #10'WHERE auth_view=0 AND auth_read=0'
        + #10'ORDER BY forum_order';
      Data.Open;
      while not Data.EOF do
      begin
        AddUrl(BaseURL + 'forum/' + Data.FieldByName('forum_id').AsString + '/'
          + GenerateSlug(Data.FieldByName('forum_name').AsString),
          0, 'weekly', '0.7');
        Data.Next;
      end;
    finally
      Free;
    end;
  end;
end;

procedure TSitemapController.AddTopics;
begin
  // lastmod = time of the newest post in the topic (replies do not update
  // phpbb_topics, so it is taken from phpbb_posts)
  with TSimpleModel.Create('phpbb_topics') do
  begin
    try
      Data.SQL.Text := 'SELECT t.topic_id, t.topic_title, f.forum_name,'
        + #10'  GREATEST(t.topic_time, COALESCE(p.last_time, 0)) last_time'
        + #10'FROM phpbb_topics t'
        + #10'JOIN phpbb_forums f ON f.forum_id=t.forum_id'
        + #10'LEFT JOIN (SELECT topic_id, MAX(post_time) last_time'
        + #10'  FROM phpbb_posts GROUP BY topic_id) p ON p.topic_id=t.topic_id'
        + #10'WHERE t.topic_status=0 AND f.auth_view=0 AND f.auth_read=0'
        + #10'ORDER BY last_time DESC';
      Data.Open;
      while not Data.EOF do
      begin
        AddUrl(BaseURL + 'thread/'
          + GenerateSlug(Data.FieldByName('forum_name').AsString) + '/'
          + Data.FieldByName('topic_id').AsString + '/'
          + GenerateSlug(Data.FieldByName('topic_title').AsString) + '/',
          UnixToDateTime(Data.FieldByName('last_time').AsLargeInt),
          'monthly', '0.6');
        Data.Next;
      end;
    finally
      Free;
    end;
  end;
end;

procedure TSitemapController.AddNews;
begin
  with TSimpleModel.Create('news') do
  begin
    try
      Data.SQL.Text := 'SELECT nid, urltitle, unix_timestamp(`from`) ts'
        + #10'FROM news'
        + #10'WHERE status_id=0 AND published_status=0 AND `from`<NOW()'
        + #10'ORDER BY `from` DESC';
      Data.Open;
      while not Data.EOF do
      begin
        AddUrl(BaseURL + 'news/' + Data.FieldByName('nid').AsString + '/'
          + Data.FieldByName('urltitle').AsString,
          UnixToDateTime(Data.FieldByName('ts').AsLargeInt),
          'monthly', '0.8');
        Data.Next;
      end;
    finally
      Free;
    end;
  end;
end;

// GET Method Handler
procedure TSitemapController.Get;
begin
  DataBaseInit;

  FXml.Clear;
  FXml.Add('<?xml version="1.0" encoding="UTF-8"?>');
  FXml.Add('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  AddStaticPages;
  AddNews;
  AddForums;
  AddTopics;
  FXml.Add('</urlset>');

  Response.ContentType := 'application/xml; charset=utf-8';
  Response.SetCustomHeader('Cache-Control', 'public, max-age=3600');
  Response.Content := FXml.Text;
end;

end.
