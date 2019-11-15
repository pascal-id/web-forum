var article_title = "";
var article_hometext = "";
var article_bodytext = "";

$(function () {

  $("#btnSubmit").click(function(event){
    event.preventDefault();
    var article = {};
    article.title = $('#article-title').val();
    article.date = $('#article-date').val();
    //article.hometext = $('#article-hometext').val();
    //article.bodytext = encodeURIComponent($('#article-bodytext').val());
    article.hometext = encodeURIComponent(hometextMde.value());
    article.bodytext = encodeURIComponent(bodytextMde.value());
    $('#article-title').removeClass('is-invalid');

    if (0 == article.title.length){
      $('#article-title').addClass('is-invalid');
      $('#article-title').focus();
      return;
    }
    if (0 == article.hometext.length){
      $('.hometext-container').addClass('is-invalid');
      $('#article-hometext').focus();
      return;
    }
    if (0 == article.bodytext.length){
      $('.bodytext-container').addClass('is-invalid');
      $('#article-bodytext').focus();
      return;
    }

    swal("Are you sure you want to do this?", {
      buttons: ["No", "Yes"],
    }).then((value) => {
      if (value) {
        SaveNewArticle(article);
      }else{
        $('textarea#bodytext').focus();
      };
    });
    
  });

  $("#btnCancel").click(function(event){
    event.preventDefault();

    swal("Are you sure you want to do this?", {
      buttons: ["Oh nooo...!", "Yesss!"],
    }).then((value) => {
      if (value) {
        docCookies.removeItem('article-title');
        docCookies.removeItem('article-hometext');
        docCookies.removeItem('article-bodytext');
        location.href = BaseURL + 'news/new/';
    
      }else{
        $('#title').focus();
      };
    });
    
  });

  $('#article-date').datetimepicker({
    format:'d-m-Y H:i'
  });

  // reload from cookie draft
  article_title = docCookies.getItem('article_title');
  article_hometext = docCookies.getItem('article_hometext');
  article_bodytext = docCookies.getItem('article_bodytext');
  $('#article-title').val(article_title);
  $('#article-hometext').val(article_hometext);
  $('#article-bodytext').val(article_bodytext);

  // autosave draft
  /*
  setInterval(function(){
    var t = $('#article-title').val();
    if (t.length > 3){
      docCookies.setItem('article_title', t, null, '/');
    }
    t = $('#article-hometext').val();
    if (t.length > 3){
      docCookies.setItem('article_hometext', t, null, '/');
    }
    t = $('#article-bodytext').val();
    if (t.length > 3){
      docCookies.setItem('article_bodytext', t, null, '/');
    }
  }, 3000);
  */
  
  //$.summernote.dom.emptyPara = "<div><br></div>---";
  $('.article-textarea-x').summernote({
    //enterHtml: "<br>\n-", // '<br>', '<p>&nbsp;</p>', '<p><br></p>', '<div><br></div>'
    airMode: true
  }).on("summernote.enter", function(we, e) {
    $(this).summernote("pasteHTML", "<br>\n");
    e.preventDefault();
  });

  // markdown
  var hometextMde = new SimpleMDE({
    toolbar: [
      "bold", 
      "italic",
      "strikethrough",
      "heading-2",
      "heading-3",
      "code",
      "link",
      "image",
      "|",
      "preview", "side-by-side", "fullscreen"],
    spellChecker: false,
    element: $("#article-hometext")[0] 
  });
  var bodytextMde = new SimpleMDE({
    toolbar: [
      "bold", 
      "italic",
      "strikethrough",
      "heading-2",
      "heading-3",
      "code",
      "link",
      "image",
      "|",
      "preview", "side-by-side", "fullscreen"],
    spellChecker: false,
    element: $("#article-bodytext")[0] 
  });
  
  $('#article-title').focus();
});

function SaveNewArticle(AArticle){
  $.ajax({
    type: "POST",
    url: BaseURL + 'news/new/',
    crossDomain: true,
    data: AArticle,
    headers: {'Token':localToken},
    success: function(result){
      docCookies.setItem('article_title', '', null, '/');
      docCookies.setItem('article_hometext', '', null, '/');
      docCookies.setItem('article_bodytext', '', null, '/');
      
      swal('Siap ...', 'Draft artikel telah disimpan, mohon ditunggu untuk approval dari moderator.').then((value) => {
        location.href = BaseURL + 'news/new/';
      });
    },
    error: function (request, status, error) {
      log(request.responseText);
      swal('Maaf, gagal melakukan penyimpanan');
      //toastr.danger('gagal');
    }
  });
}