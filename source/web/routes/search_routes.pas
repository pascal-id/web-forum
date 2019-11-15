unit search_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses search_controller;

initialization
  Route[ '/'] := TSearchController; // Main Module

end.

