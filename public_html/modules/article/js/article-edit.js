var ApiNewsDetail = BaseURL + 'api/news/';
var homeTextMde;
var bodyTextMde;

$(function () {

  $(".btnEditArticle").click(function(event){
    event.preventDefault();
    swal('Double-Click ke text yang akan diedit.');
  });

  // hometext
  var homeTextId = ".article .card-body .hometext";
  $(homeTextId).dblclick(function() { 
    var textareaHtml = '<div><textarea id="hometextEditor" class=""></textarea>'
      + '<div class="float-right">'
      + '<a href="#" class="" title="Save" onClick="homeTextSavePrepare(event)"><i class="fas fa-save"></i></a>'
      + '&nbsp;'
      + '<a href="#" class="" title="Cancel" onClick="homeTextCancel(event)"><i class="far fa-times-circle"></i></a>'
      + '</div></div>';
    var url = ApiNewsDetail + referenceId + '/' + referenceSlug + '?preview=1';
    $.ajax({
      type: "GET",
      url: url,
      crossDomain: true,
      headers: {'Token':'global'},
      success: function(result){
        if (0==result.code){
          if (typeof result.data !== 'undefined') {
            var homeText = result.data[0].hometext;
            $( textareaHtml ).insertAfter( $(homeTextId) );
            homeTextMde = new SimpleMDE({
              toolbar: [],
              spellChecker: false,
              status: false,
              element: $(".article .card-body textarea#hometextEditor")[0] 
            });
            homeTextMde.value(homeText);
            $(homeTextId).hide();        
          }
        }
      }
    });    
  });

  // bodytext
  var bodyTextId = ".article .card-body .bodytext";
  $(bodyTextId).dblclick(function() { 
    var textareaHtml = '<div><textarea id="bodytextEditor" class=""></textarea>'
      + '<div class="float-right">'
      + '<a href="#" class="" title="Save" onClick="bodyTextSavePrepare(event)"><i class="fas fa-save"></i></a>'
      + '&nbsp;'
      + '<a href="#" class="" title="Cancel" onClick="bodyTextCancel(event)"><i class="far fa-times-circle"></i></a>'
      + '</div></div>';
    var url = ApiNewsDetail + referenceId + '/' + referenceSlug + '?preview=1';
    $.ajax({
      type: "GET",
      url: url,
      crossDomain: true,
      headers: {'Token':'global'},
      success: function(result){
        if (0==result.code){
          if (typeof result.data !== 'undefined') {
            var bodyText = result.data[0].bodytext;
            $( textareaHtml ).insertAfter( $(bodyTextId) );
            bodyTextMde = new SimpleMDE({
              toolbar: [],
              spellChecker: false,
              status: false,
              element: $(".article .card-body textarea#bodytextEditor")[0] 
            });
            bodyTextMde.value(bodyText);
            $(bodyTextId).hide();        
          }
        }
      }
    });
  });


});

function homeTextSavePrepare(e){
  e.preventDefault();
  swal("Are you sure you want to do this?", {
    buttons: ["No", "Yes"],
  }).then((value) => {
    if (value) {
      homeTextSave(e);
    }else{
      homeTextCancel(e);
    };
  });
}
function homeTextSave(e){
  var postData = {};
  postData.homeText = encodeURIComponent(homeTextMde.value());
  postData.id = referenceId;

  $.ajax({
    type: "PUT",
    url: referenceUrl,
    crossDomain: true,
    data: postData,
    headers: {'Token':'global'},
    success: function(result){
      if (200==result.code){
        log('save success');
        PageReload();
      }
    },
    error: function (request, status, error) {
      console.log('error');
      console.log(request.responseText);
    }      
  });
}

function bodyTextSavePrepare(e){
  e.preventDefault();
  swal("Are you sure you want to do this?", {
    buttons: ["No", "Yes"],
  }).then((value) => {
    if (value) {
      bodyTextSave(e);
    }else{
      bodyTextCancel(e);
    };
  });
}

function bodyTextSave(e){
  var postData = {};
  postData.bodyText = encodeURIComponent(bodyTextMde.value());
  postData.id = referenceId;

  $.ajax({
    type: "PUT",
    url: referenceUrl,
    crossDomain: true,
    data: postData,
    headers: {'Token':'global'},
    success: function(result){
      if (200==result.code){
        log('save success');
        PageReload();
      }
    },
    error: function (request, status, error) {
      console.log('error');
      console.log(request.responseText);
    }      
  });
}

function homeTextCancel(e){
  e.preventDefault(); 
  PageReload();
}
function bodyTextCancel(e){
  e.preventDefault(); 
  PageReload();
}

