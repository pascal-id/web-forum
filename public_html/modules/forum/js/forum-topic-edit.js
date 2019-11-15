var ReplyTextMde;

$(function () {

  $("#btnSubmit").click(function(event){
    event.preventDefault();
    var topic = {};
    topic.title = $('#topic-title').val();
    topic.message = ReplyTextMde.value();;
    $('#topic-title').removeClass('is-invalid');
    $('#topic-message').removeClass('is-invalid');

    if (0 == topic.title.length){
      $('#topic-title').addClass('is-invalid');
      $('#topic-title').focus();
      return;
    }
    if (topic.message.length < 10){
      $('#topic-message').addClass('is-invalid');
      $('#topic-message').focus();
      swal('lengkapi dulu pesannya ...');
      return;
    }

    swal("Are you sure you want to do this?", {
      buttons: ["No", "Yes"],
    }).then((value) => {
      if (value) {
        SaveNewTopic(topic);
      }else{
        $('#topic-title').focus();
      };
    });
    
  });

  $("#btnCancel").click(function(event){
    event.preventDefault();

    swal("Are you sure you want to do this?", {
      buttons: ["Oh nooo...!", "Yesss!"],
    }).then((value) => {
      if (value) {
        location.href = BaseURL + 'forum/';    
      }else{
        $('#topic-title').focus();
      };
    });
    
  });

  /*
  TopicNewTextMde = new SimpleMDE({
    toolbar: [],
    spellChecker: false,
    status: false,
    element: $("textarea#topic-message")[0] 
  });
  */
  ReplyTextMde = new SimpleMDE({
    toolbar: [],
    spellChecker: false,
    status: false,
    element: $("textarea#ReplyText")[0] 
  });
  $('textarea#ReplyText').focus(function() {
    //$('#btnReply').removeClass('hide');
  });

  $('textarea#ReplyText').blur(function() {
    //$('#btnReply').addClass('hide');
  });

  $("#btnReply").click(function(event){
    SendThreadReply($(this));
    //$('textarea#ReplyText').addClass('disable');
  });
});

function SendThreadReply(element){
  var replyMessage = ReplyTextMde.value();
  if (replyMessage.length < 3){
    swal('Maaf, gagal melakukan penyimpanan.');
    return;
  }

  var postData = {};
  postData.id = Thread.id;
  postData.message = encodeURIComponent(replyMessage);
  

  $.ajax({
    type: "POST",
    url: Thread.url,
    crossDomain: true,
    data: postData,
    headers: {'Token':localToken},
    success: function(result){
      var postId = result.post_id;
      swal('Terima kasih ...', 'reply telah dikirimkan..').then((value) => {
        url = Thread.url + '?page=' + Thread.currentPage + '#post-' + postId;
        location.href = url;
        window.location.reload(true);
      });
    },
    error: function (request, status, error) {
      log(request.responseText);
      swal('Maaf, gagal melakukan penyimpanan');
    }
  });

}

function SaveNewTopic(ATopic){
  ATopic.message = encodeURIComponent( ATopic.message);
  $.ajax({
    type: "POST",
    url: TopicAddApiUrl,
    crossDomain: true,
    data: ATopic,
    headers: {'Token':localToken},
    success: function(result){
      swal('Terima kasih ...', 'Topik baru telah dikirimkan..').then((value) => {
        location.href = BaseURL + 'forum/'+result.forum_id+'/new-topic/';
      });
    },
    error: function (request, status, error) {
      log(request.responseText);
      swal('Maaf, gagal melakukan penyimpanan');
    }
  });
}

