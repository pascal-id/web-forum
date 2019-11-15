unit auth_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses auth_controller, auth_facebook_controller;

initialization
  Route[ '/facebook/'] := TAuthFacebookController;
  Route[ '/'] := TAuthController; // Main Controller

end.

