# Topic

Endppoint: /topic/

## Get Recent Topic

Endpoint: /recent/

Methode: GET

Parameters:

| Name  |   | Type  |  Description |
|---|---|---|---|
| limit | optional | integer  | result limit |
| page | optional | integer  | page number |

Result Format:

```
{
  "code": 0,
  "count": 2,
  "info": {
    "title": "topic title",
    "replies": 3
  },
  "data": [
    {
      "post_id": 2204,
      "post_time": 1133668807,
      "username": "imunk",
      "post_text": "{text}"
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
curl "http://www.pascal-id.test/api/topic/thread/123/the-title/"
```


## Get Last Topic


Endpoint: /last/

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
      "topic_id": 8078,
      "topic_title": "Ada apa dengan Pascal-id.org ??",
      "topic_time": 1352000490,
      "username": "luridarmawan",
      "cat_id": 1,
      "forum_id": "1",
      "forum_name": "Pascal Indonesia",
      "category_name": "Pascal Indonesia"
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
curl "http://www.pascal-id.test/api/topic/last/?limit=2"
```


## Show Thread


Endpoint: /thread/{topicId}/{slug}/

Methode: GET

Parameters:

| Name  |   | Type  |  Description |
|---|---|---|---|
| page | optional | integer  | page number, start from 1 |

Result Format:

```
{
  "code": 0,
  "count": 2,
  "data": [
    {
      "topic_id": 8078,
      "topic_title": "Ada apa dengan Pascal-id.org ??",
      "topic_time": 1352000490,
      "username": "luridarmawan",
      "cat_id": 1,
      "forum_id": "1",
      "forum_name": "Pascal Indonesia",
      "category_name": "Pascal Indonesia"
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
curl "http://www.pascal-id.test/api/topic/thread/8035/the-title-of-thread/?page=5"
```

