let ApiURL = '';
let ApiToken = '';

$(function () {

  'use strict'

  moment.locale('en', {
    relativeTime: {
      future: 'in %s',
      past: '%s ago',
      s:  'seconds',
      ss: '%ss',
      m:  'a minute',
      mm: '%dm',
      h:  'an hour',
      hh: '%dhr',
      d:  'a day',
      dd: '%dd',
      M:  'a month',
      MM: '%dmo',
      y:  'a year',
      yy: '%dyr'
    }
  });

  $(".thread-more").click(function(event){
    event.preventDefault();
    if ((PageOfThread+1) > Thread.maxNumberOfPage){
      $("#thread-more").html('');
      return;
    }
    let page = PageOfThread + 1;
    let html = ""
    ApiURL = BaseURL + 'api/topic/thread/'+ThreadId+'/'+ThreadSlug+'/?page='+page;
    $.ajax({
      type: "GET",
      url: ApiURL,
      crossDomain: true,
      headers: {'Token':ApiToken},
      success: function(result){
        let jumpAnchor = "";
        if (0==result.code){
          if (typeof result.data !== 'undefined') {
            result.data.forEach(el => {
              if ("" === jumpAnchor) jumpAnchor = "#post-"+el.post_id;
              let dateString = moment.unix(el.post_time).fromNow(); 
              let originalDateString = moment.unix(el.post_time).format("YYYY-MM-DD");
              html = '<div id="post-'+el.post_id+'">';
              html += '<i class="user-photo-small"><img class="img-circle ximg-bordered-sm" src="'+ImageURL+'profile-image/'+el.gravatar+'.jpg" alt="user image" onerror="this.onerror=null; this.src=\'/profile-image/default.png\';"></i>';
              html += '<div class="timeline-item">';
              html += '  <span class="time" title="'+originalDateString+'"><i class="far fa-clock"></i> '+dateString+'</span>';
              html += '  <h3 class="timeline-header"><a href="/profile/'+el.username+'">'+el.username+'</a></h3>';
              html += '  <div class="timeline-body">'+el.post_text+'</div>'
              html += '</div>';
              html += '</div>';
              $( html ).insertBefore( $( "#thread-more" ) );
            });
            PageOfThread++;
            if ((PageOfThread+1) > Thread.maxNumberOfPage){
              $("#thread-more").html('');
            }
            if(history.pushState) {
              let newURL = Thread.url+'?page='+PageOfThread;
              history.pushState(null, null, newURL);
            }
            $('html,body').animate({scrollTop: $(jumpAnchor).offset().top-60},'slow');
          }
        }
      }
    });

  });

  FormattingCode();

  //$("#report-obsolete").click(function(event){
  //  event.preventDefault();
    //todo: report obsolete
  //});

});

