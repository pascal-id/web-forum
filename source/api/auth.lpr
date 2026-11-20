program auth;

{$mode objfpc}{$H+}

uses
  {$IFNDEF Windows}cthreads,{$ENDIF}
  fastplaz_app, sysutils, fastplaz_handler, common, auth_controller, auth_routes,
  auth_facebook_controller, auth_user_model, auth_token_model;

begin
  Application.Title:='Auth';
  Application.Email := Config.GetString(_SYSTEM_WEBMASTER_EMAIL);
  if Application.Email = '' then
    Application.Email := 'webmaster@' + GetEnvironmentVariable('SERVER_NAME');
  Application.DefaultModuleName := string( Config.GetValue(_SYSTEM_MODULE_DEFAULT, 'main'));
  Application.ModuleVariable := string( Config.GetValue(_SYSTEM_MODULE_VARIABLE, 'mod'));
  Application.AllowDefaultModule := True;
  Application.RedirectOnErrorURL := string( Config.GetValue(_SYSTEM_ERROR_URL, '/'));
  Application.RedirectOnError:= Config.GetValue( _SYSTEM_ERROR_REDIRECT, false);

  Application.OnGetModule := @FastPlasAppandler.OnGetModule;
  Application.PreferModuleName := True;
  {$if FPC_FULLVERSION >= 30004}
  Application.LegacyRouting := True;
  {$endif}

  // startup banner, standalone (HTTP) mode only
  ShowStandaloneBanner;

  Application.Initialize;
  Application.Run;
end.
