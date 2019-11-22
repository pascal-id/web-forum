unit news_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses news_controller, news_search_controller;

initialization
  Route[ '/search/'] := TNewsSearchController;
  Route[ '/last/'] := TNewsLastModule;
  Route[ '/([0-9]+)/(.*)'] := TNewsDetailModule;
  Route[ '/'] := TNewsModule;

end.

