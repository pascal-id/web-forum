unit forum_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses forum_controller;

initialization
  Route[ '/'] := TForumModule; // Main Module

end.

