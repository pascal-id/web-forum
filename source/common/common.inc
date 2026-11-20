const
  ERR_UNSUPPORTED_METHOD = 'Unsupported method.';
  ERR_INVALID_PARAMETER = 'Invalid Parameter';
  ERR_INVALID_QUERY = 'Invalid Query or data not found';
  ERR_DATA_NOT_FOUND = 'Data not found';
  ERR_NOT_PERMITTED = 'Not Permitted';
  ERR_UNKNOWN = 'Error unknown';

  ERR_AUTH_EMAIL_REQUIRED = 'Email required.';
  ERR_AUTH_INVALID_TOKEN = 'Invalid token.';

  // default Facebook App ID (sama dengan FacebookAppId di themes/.../js/facebook.js),
  // bisa di-override lewat config: "facebook": { "app_id": "..." }
  FACEBOOK_APP_ID = '2429307740650423';

  TOPIC_DEFAULT_LIMIT = 25;
  THREAD_DEFAULT_LIMIT = 10;
  NEWS_DEFAULT_LIMIT = 25;

  DEFAULT_OGIMAGE = 'logo.png';
  FORUM_DEFAULT_OGIMAGE = 'logo-forum.png';
  TOPIC_DEFAULT_OGIMAGE = 'logo-topic.png';
  THREAD_DEFAULT_OGIMAGE = 'logo-topic.png';
  ARTICLE_DEFAULT_OGIMAGE = 'logo-article.png';
  SEARCH_DEFAULT_OGIMAGE = 'logo-search.png';

  ARTICLE_SAVE_ERROR = 'failed to save article';
  TOPIC_SAVE_ERROR = 'failed to save new topic';

  TAG_USER_CAN_EDIT = '__can_edit__';
  TAG_IS_LOGGED_IN = '__is_logged_in__';
  TAG_USERNAME = '__username__';
  TAG_GRAVATAR = '__gravatar__';
  TAG_IP_ADDRESS = '__ipaddress__';
  TAG_CSRF_TOKEN = '__csrf_token__';

  // header yang dikirim JS (app.js) di setiap request POST/PUT/DELETE
  CSRF_HEADER = 'X-CSRF-Token';
  CSRF_SESSION_KEY = 'csrf_token';
  ERR_CSRF_INVALID = 'Invalid or missing CSRF token. Reload the page.';

  ACTIVITY_MONTH_FORMAT = 'MMM yyyy';
  ACTIVITY_DATE_FORMAT = 'yyyy-mm-dd';

  LANGUAGE_DEFAULT = 'id';


