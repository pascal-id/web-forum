
$(function () {

  'use strict'

  $( "#login-form input" ).prop( "disabled", true );
  $( "#login-form button" ).prop( "disabled", true );

  $("#btnFacebookLogin").click(function(event){
    event.preventDefault();
    Facebook_Connect();
  });

  $("#btnFacebookLogout").click(function(event){
    event.preventDefault();
    Facebook_Disconnect();
  });

})
