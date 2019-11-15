unit auth_routes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fastplaz_handler;

implementation

uses info_controller, auth_controller, auth_login_controller,
  auth_facebook_controller, auth_logout_controller, auth_token_controller;

initialization
  Route[ '/facebook/'] := TAuthFacebookController;
  Route[ '/login/'] := TAuthLoginController;
  Route[ '/logout/'] := TAuthLogoutController;
  Route[ '/token/'] := TAuthTokenController;
  Route[ '/'] := TAuthController; // Main Controller

end.

