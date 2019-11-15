# News

Endppoint: /news/

## Get Last News

Endpoint: /news/last/

Methode: GET

Parameters:

| Name  |   | Type  |  Description |
|---|---|---|---|
| limit | optional | integer  | result limit |

Result Format:

```
{
  "code": 0,
  "count": 2,
  "data": [
    {
      "nid": 307,
      "slug": "{article-slug}",
      "title": "The Title",
      "hometext": "Summary Text",
      "date": "2011-03-30 10:59:06",
      "contributor": "code",
      "counter": 2439,
      "category_id": 10015,
      "category_name": "Articles"
    },
    .
    .
    .

  ]
}

```

### Usage

Example:

```
curl "http://www.pascal-id.test/api/news/last/?limit=2"
```


Result:

```
{
  "code": 0,
  "count": 2,
  "data": [
    {
      "nid": 307,
      "slug": "lazarus-0.9.30-released",
      "title": "Lazarus 0.9.30 released",
      "hometext": "The Lazarus team is glad to announce the 0.9.30 release. This release<br />is based on fpc 2.4.2.<br /><br />This release is available for download at the SourceForge download page:<br /><a href=\"http://sourceforge.net/projects/lazarus/files/\" title=\"download lazarus\" target=\"_blank\">http://sourceforge.net/projects/lazarus/files/</a><br /><br /><br />",
      "date": "2011-03-30 10:59:06",
      "contributor": "code",
      "counter": 2439,
      "category_id": 10015,
      "category_name": "Announcement"
    },
    {
      "nid": 307,
      "slug": "lazarus-0.9.30-released",
      "title": "Lazarus 0.9.30 released",
      "hometext": "The Lazarus team is glad to announce the 0.9.30 release. This release<br />is based on fpc 2.4.2.<br /><br />This release is available for download at the SourceForge download page:<br /><a href=\"http://sourceforge.net/projects/lazarus/files/\" title=\"download lazarus\" target=\"_blank\">http://sourceforge.net/projects/lazarus/files/</a><br /><br /><br />",
      "date": "2011-03-30 10:59:06",
      "contributor": "code",
      "counter": 2439,
      "category_id": 10002,
      "category_name": "Articles"
    }
  ]
}
```


## Get News Detail

Endpoint: /news/{id}/{date}/{slug}

Methode: GET


### Usage

Example:

```
curl "http://www.pascal-id.test/api/news/163/2019-10-20/the-article-name" 
```

Result:

```
{
  "code": 0,
  "count": 1,
  "data": [
    {
      "nid": 163,
      "slug": "tuju-baris-n-di-richedit",
      "title": "Tuju baris N di richedit",
      "hometext": "Bro ... iseng ajah nih, kalo dikau mau menuju baris yang diinginkan pada richedit ... ada dikit tips ... :<br />\r\n",
      "bodytext": "<br />\r\n<code><br />\r\nprocedure TForm1.Button1Click(Sender: TObject);<br />\r\nvar<br />\r\n  LineNr: integer;<br />\r\nbegin<br />\r\n  LineNr := StrToInt(Edit1.Text);<br />\r\n  RichEdit1.SelStart := RichEdit1.Perform(EM_LINEINDEX, LineNr, 0);<br />\r\n  Memo1.SelLength := 0;<br />\r\nend;<br />\r\n</code>",
      "notes": "",
      "date": "2007-04-03 06:59:40",
      "contributor": "manz_delphi",
      "counter": 2356,
      "category_id": 10002,
      "category_name": "Articles"
    }
  ]
}
```
