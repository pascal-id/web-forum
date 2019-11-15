# Forum

Endppoint: /forum/

## Get Forum List

Endpoint: /

Methode: GET


Result Format:

```
{
  "code": 0,
  "count": 27,
  "data": [
    {
      "forum_id": "1",
      "forum_name": "Pascal Indonesia",
      "forum_desc": "Hal-hal umum yang berkaitan dengan Pascal Indonesia",
      "forum_topics": 1721,
      "forum_last_post_id": 55593,
      "cat_id": 1,
      "category": "Pascal Indonesia"
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
curl "http://www.pascal-id.test/api/forum/"
```
