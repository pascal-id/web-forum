var localToken = '';
$(function () {
  
  'use strict'

  $.ajaxSetup({ cache: true });

  // Make the dashboard widgets sortable Using jquery UI
  $('.connectedSortable').sortable({
    placeholder         : 'sort-highlight',
    connectWith         : '.connectedSortable',
    handle              : '.card-header, .nav-tabs',
    forcePlaceholderSize: true,
    zIndex              : 999999
  })

  $('.connectedSortable .card-header, .connectedSortable .nav-tabs-custom').css('cursor', 'move')

  $(".btn-login").click(function(event){
    event.preventDefault();
    Facebook_Connect();
  });

  $(".btn-logout").click(function(event){
    event.preventDefault();
    docCookies.removeItem('token');
    Facebook_Disconnect();
  });

  $("#obsolete-modal .modal-submit").click(function(event){
    event.preventDefault();
    $(this).html('wait ...');
    ObsoloteSubmit(this);
  });

  //EnableLoginRequiredFeature();

  //docCookies.setItem('token', '[token]', null, '/');
  localToken = docCookies.getItem('token');
  if (localToken !== null){
    CheckIsValidToken(localToken);
  }
});


btnGoTop = document.getElementById("btnGoTop");
window.onscroll = function() {scrollFunction()};
function scrollFunction() {
  if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
    btnGoTop.style.display = "block";
  } else {
    btnGoTop.style.display = "none";
  }
}
function GoTop() {
  document.body.scrollTop = 0; // For Safari
  document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

function GlobalLogout(){

}

function EnableLoginRequiredFeature(){
  $(".login-required").removeClass('login-required');
}

function getSearchParams(k){
  var p={};
  location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi,function(s,k,v){p[k]=v})
  return k?p[k]:p;
}

function CheckIsValidToken(AToken){
  $.ajax({
    type: "GET",
    url: BaseURL + 'auth/token/',
    crossDomain: true,
    headers: {'Token':AToken},
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
}

function ObsoloteSubmit(el){
  var description = $('#obsolete-description').val();
  var postData = {};
  if (description.length < 3){
    $('#obsolete-description').addClass('is-invalid');
    $('#obsolete-description').focus();
    $(el).html('Submit');
    return;
  }
  $('#obsolete-description').removeClass('is-invalid');
  postData.module = moduleName;
  postData.id = referenceId;
  postData.title = referenceTitle;
  postData.description = description;
  $.ajax({
    type: "POST",
    url: BaseURL + 'obsolete/',
    crossDomain: true,
    data: postData,
    headers: {'Token':authToken},
    success: function(result){
      $(el).html('Submit');
      console.log(result);  
      $('#obsolete-modal').modal('hide');
      toastr.info('Report sent. Thank you.');
    },
    error: function (request, status, error) {
      $(el).html('Submit');
      console.log(request.responseText);
      $('#obsolete-modal').modal('hide');
    }      
  });

}

docCookies = {
  getItem: function (sKey) {
    if (!sKey || !this.hasItem(sKey)) { return null; }
    return unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1"));
  },
  /**
  * docCookies.setItem(sKey, sValue, vEnd, sPath, sDomain, bSecure)
  *
  * @argument sKey (String): the name of the cookie;
  * @argument sValue (String): the value of the cookie;
  * @optional argument vEnd (Number, String, Date Object or null): the max-age in seconds (e.g., 31536e3 for a year) or the
  *  expires date in GMTString format or in Date Object format; if not specified it will expire at the end of session; 
  * @optional argument sPath (String or null): e.g., "/", "/mydir"; if not specified, defaults to the current path of the current document location;
  * @optional argument sDomain (String or null): e.g., "example.com", ".example.com" (includes all subdomains) or "subdomain.example.com"; if not
  * specified, defaults to the host portion of the current document location;
  * @optional argument bSecure (Boolean or null): cookie will be transmitted only over secure protocol as https;
  * @return undefined;
  **/
  setItem: function (sKey, sValue, vEnd, sPath, sDomain, bSecure) {
    if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/.test(sKey)) { return; }
    var sExpires = "";
    if (vEnd) {
      switch (typeof vEnd) {
        case "number": sExpires = "; max-age=" + vEnd; break;
        case "string": sExpires = "; expires=" + vEnd; break;
        case "object": if (vEnd.hasOwnProperty("toGMTString")) { sExpires = "; expires=" + vEnd.toGMTString(); } break;
      }
    }
    document.cookie = escape(sKey) + "=" + escape(sValue) + sExpires + (sDomain ? "; domain=" + sDomain : "") + (sPath ? "; path=" + sPath : "") + (bSecure ? "; secure" : "");
  },
  removeItem: function (sKey) {
    if (!sKey || !this.hasItem(sKey)) { return; }
    var oExpDate = new Date();
    oExpDate.setDate(oExpDate.getDate() - 1);
    document.cookie = escape(sKey) + "=; expires=" + oExpDate.toGMTString() + "; path=/";
  },
  hasItem: function (sKey) { return (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie); }
};

function SetStorage(AKey, AValue){
  AContent = AValue;
  if (typeof AValue === 'object'){
    AContent = JSON.stringify(AValue);
  }
  localStorage.setItem(AKey, AContent);
}
function GetStorage(AKey){
  let result = localStorage.getItem(AKey);
  if (null == result){
    result = '[]';
  }
  result = JSON.parse(result);
  return result;    
}

function FormattingCode(){
  var pre = document.getElementsByTagName('pre'),
      pl = pre.length;
  for (var i = 0; i < pl; i++) {
      pre[i].innerHTML = '<span class="line-number"></span>' + pre[i].innerHTML + '<span class="cl"></span>';
      var num = pre[i].innerHTML.split(/\n/).length;
      for (var j = 0; j < num; j++) {
          var line_num = pre[i].getElementsByTagName('span')[0];
          line_num.innerHTML += '<span>' + (j + 1) + '</span>';
      }
  }
}

function auto_grow(element) {
  element.style.height = "5px";
  element.style.height = (element.scrollHeight)+"px";
}

function PageReload(){
  window.location.reload(true);
}

function log(AMessage){
  console.log(AMessage);
}
