program forumpascal;

{$mode objfpc}{$H+}

uses
  {$IFNDEF Windows}cthreads,{$ENDIF}
  fpcgi, sysutils, fastplaz_handler, common, index_controller, routes,
  thread_controller, common_lib, forum_home_controller, breadcrumb_controller,
  topic_list_controller, category_controller, category_model,
  article_controller, article_detail_controller, user_controller,
  profile_controller, user_model, obsolete_controller, obsolete_model,
  article_new_controller, topic_new_controller, topic_post_model,
  topic_post_text_model;

begin
  Application.Title:='Forum Pascal';
  Application.Email := string( Config.GetValue(_SYSTEM_WEBMASTER_EMAIL,UTF8Decode('webmaster@' + GetEnvironmentVariable('SERVER_NAME'))));
  Application.DefaultModuleName := string( Config.GetValue(_SYSTEM_MODULE_DEFAULT, 'main'));
  Application.ModuleVariable := string( Config.GetValue(_SYSTEM_MODULE_VARIABLE, 'mod'));
  Application.AllowDefaultModule := True;
  Application.RedirectOnErrorURL := string( Config.GetValue(_SYSTEM_ERROR_URL, '/'));
  Application.RedirectOnError:= Config.GetValue( _SYSTEM_ERROR_REDIRECT, false);

  Application.OnGetModule := @FastPlasAppandler.OnGetModule;
  Application.PreferModuleName := True;
  {$if (fpc_version=3) and (fpc_release>=0) and (fpc_patch>=4)}
  Application.LegacyRouting := True;
  {$endif}

  Application.Initialize;
  Application.Run;
end.
