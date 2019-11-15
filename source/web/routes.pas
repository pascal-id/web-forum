unit routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses info_controller, index_controller, thread_controller, forum_home_controller,
  topic_list_controller, category_controller, article_controller, article_new_controller,
  article_detail_controller, user_controller, profile_controller,
  obsolete_controller, topic_new_controller;

initialization
  //Route[ '/info'] := TInfoModule;
  //Route.Add('thread', '/thread/(.*)/([0-9]+)/(.*)', TThreadController);
  Route[ '/thread/(.*)/([0-9]+)/(.*)'] := TThreadController;
  Route[ '/forum/category/([0-9]+)/(.*)'] := TCategoryController;
  Route[ '/forum/([0-9]+)/(.*)/new/'] := TTopicNewController;
  Route[ '/forum/([0-9]+)/(.*)'] := TTopicListController;
  Route[ '/forum'] := TForumController;
  Route[ '/article/([0-9]+)/(.*)'] := TArticleDetailController;
  Route[ '/article/new/'] := TArticleNewController;
  Route[ '/article/'] := TArticleController;
  Route[ '/news/([0-9]+)/(.*)'] := TArticleDetailController;
  Route[ '/news/new/'] := TArticleNewController;
  Route[ '/news/'] := TArticleController;
  Route[ '/profile/(.*)'] := TProfileController;
  Route[ '/user'] := TUserController;
  Route['/obsolete/'] := TObsoleteController;
  Route[ '/'] := TIndexController; // Main Module

end.

