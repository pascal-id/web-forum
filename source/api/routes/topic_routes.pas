unit topic_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses topic_controller, empty_controller, thread_controller, topic_search_controller;

initialization
  Route[ '/search/'] := TTopicSearchController;
  Route[ '/thread/([0-9]+)/(.*)/'] := TThreadModule;
  Route[ '/recent/'] := TTopicRecentModule;
  Route[ '/last/'] := TTopicLastModule;
  Route[ '/'] := TEmptyModule;

end.

