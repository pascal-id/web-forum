var authToken = '';
var userId = '';
var expiresIn = '';
var FacebookAppId = '2429307740650423';
var authFacebookCallbackUrl = BaseURL + 'auth/facebook/';

window.fbAsyncInit = function() {
  FB.init({
    appId      : FacebookAppId,
    cookie     : true,
    xfbml      : true,
    status     : true,
    oauth      : true, // enables OAuth 2.0
    version    : 'v5.0'
  });
    
  FB.AppEvents.logPageView();   
  FB.getLoginStatus(function(response) {
    statusChangeCallback(response);
  });      
};
(function(d, s, id){
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) {return;}
  js = d.createElement(s); js.id = id;
  js.src = "https://connect.facebook.net/en_US/sdk.js";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

function Facebook_CheckLoginState() {
  FB.getLoginStatus(function(response) {
    console.log(response);
    statusChangeCallback(response);
  });
}


function statusChangeCallback(AResponse){
  if (AResponse.status==='connected'){
    console.log('facebook connected');
    authToken = AResponse.authResponse.accessToken;
    userId = AResponse.authResponse.userID;
    expiresIn = AResponse.authResponse.expiresIn;
    
    /*
    FB.api('/me?fields=first_name,last_name,email,name,id', function(response) {
      var s = 'recheck: ' + response.name;
      console.log(s);
      console.log(response);
      //console.log(JSON.stringify(response));
    });
    */
  
    //check isTokenValid
    $.ajax({
      type: "GET",
      url: authFacebookCallbackUrl,
      crossDomain: true,
      headers: {'Token':authToken},
      success: function(result){
        if (0 == result.code){
          EnableLoginRequiredFeature();
          console.log('user logged-in: ' + result.user_name);
        }
      },
      error: function (request, status, error) {
        console.log(request.responseText);
      }
    });
  }else{
    document.getElementById('footer_status').innerHTML = '...';
  }
}

function Facebook_Connect(){
	FB.login(function(response) {
		var currentToken=response.authResponse.accessToken;
		if (response.status === 'connected') {
      Facebook_Login_Callback(currentToken);
		}else{
			console.log('NOT loged-in');
		}
  
	}, {scope: 'public_profile,email'});	
}

function Facebook_Disconnect(){
	
  $.ajax({
    type: "POST",
    url: BaseURL + 'auth/logout/',
    crossDomain: true,
    headers: {'Token':authToken},
    success: function(result){
      FB.logout(function(response) {
        //location.href = BaseURL;
        location.reload();
      });        
    },
    error: function (request, status, error) {
      console.log(request.responseText);
    }      
  });
}

function Facebook_Login_Callback(AToken) {                  
  FB.api('/me?fields=first_name,last_name,email,name,id', function(response) {
    //var s = 'Successful login for: ' + response.name;
    $.ajax({
      type: "POST",
      url: authFacebookCallbackUrl,
      crossDomain: true,
      headers: {'Token':AToken},
      data: JSON.stringify(response),
      success: function(result){
        console.log('- callback');
        console.log(result);
        docCookies.setItem('token', AToken, 86400, '/');
        location.reload();
      },
      error: function (request, status, error) {
        //console.log('error');
        console.log(request.responseText);
      }      
    });

    //document.getElementById('footer_status').innerHTML = 'Thanks for logging in, ' + response.name + '!';
  });
}

function testAPI() {                  
  console.log('Welcome!  Fetching your information.... ');
  FB.api('/me?fields=first_name,last_name,email,name,id', function(response) {
    var s = 'Successful login for: ' + response.name;
    console.log(s);
		console.log(response);
		console.log(JSON.stringify(response));
    document.getElementById('footer_status').innerHTML = 'Thanks for logging in, ' + response.name + '!';
  });
}
