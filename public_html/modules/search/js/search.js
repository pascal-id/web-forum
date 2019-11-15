let ApiNewsSearchURL =  BaseURL + 'api/news/search/?q=';
let ApiTopicSearchURL = BaseURL + 'api/topic/search/?q=';
let ApiToken = '';
let NewsSearchHaveResult = false;
let TopicSearchHaveResult = false;
let SearchHistory = [];
const SEARCH_HISTORY_KEY = 'search';

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

  $("#query").keypress(function(event){
    var key = (event.keyCode ? event.keyCode : event.which); 
    var ch=String.fromCharCode(key);
    if (13 == key){
      event.preventDefault();
      SaveHistory( $("#query").val());
      SearchHistoryView();
      SetSearchView(true);
      Search($("#query").val());
    }
    
  });

  $("#btnSearch").click(function(event){
    event.preventDefault();
    SetSearchView(true);
    Search($("#query").val());
  });

  $("#search-header").addClass('hide');
  var keyword = $("#query").val();
  if (keyword.length > 2){
    setTimeout(function(){
      SetSearchView(true);
      Search(keyword);
    }, 1000); 
  }

  SearchHistory = GetStorage(SEARCH_HISTORY_KEY);
  SearchHistoryView();
});

function SaveHistory(AKeyword){
  SearchHistory.push(AKeyword);
  SetStorage(SEARCH_HISTORY_KEY, SearchHistory);    
}

function SetSearchView( IsActive){
  if (IsActive){
    $('#iconSearch').removeClass('fa-search');
    $('#iconSearch').addClass('fa-spinner fa-spin');
  }else{
    $('#iconSearch').addClass('fa-search');
    $('#iconSearch').removeClass('fa-spinner fa-spin');
  }
}

function Search(AKeyword){
  if (AKeyword.length < 3){
    $("#query").focus();
    return;
  }
  $('#search-container').addClass('lockscreen-no-margin-top');
  $('.help-block').addClass('hide');
  $('#highlight').removeClass('hide');

  NewsSearchHaveResult = false;
  TopicSearchHaveResult = false;
  NewsSearch(AKeyword);
  TopicSearch(AKeyword);

  let newURL = BaseURL + 'search/?q='+AKeyword;
  history.pushState(null, null, newURL);
}

function NewsSearch(AKeyword){
  let html = "";
  let url = "";
  $.ajax({
    type: "GET",
    url: ApiNewsSearchURL + encodeURIComponent(AKeyword),
    crossDomain: true,
    headers: {'Token':ApiToken},
    success: function(result){
      if (0==result.code){
        if (typeof result.data !== 'undefined') {
          html = '<ul>';
          result.data.forEach(el => {
            url = BaseURL + 'news/'+el.nid+'/news-search-result';
            html += '<li><a href="'+url+'" target="_blank">'+el.title+'</a></li>';
          });
          html += '</ul>';
          $('#news-search-result').removeClass('hide');
          $("#news-search-result .content").html(html);
        }
        if (0==result.count){
          $('#news-search-result').addClass('hide');
        }else{
          NewsSearchHaveResult = true;
        }
        SetSearchView(false);
      }
    }
  });
}

function TopicSearch(AKeyword){
  let html = "";
  let url = "";
  $.ajax({
    type: "GET",
    url: ApiTopicSearchURL + encodeURIComponent(AKeyword),
    crossDomain: true,
    headers: {'Token':ApiToken},
    success: function(result){
      if (0==result.code){
        if (typeof result.data !== 'undefined') {
          html = '<ul>';
          result.data.forEach(el => {
            url = BaseURL + 'thread/category/'+el.topic_id+'/topic-search-result';
            html += '<li><a href="'+url+'" target="_blank">'+el.topic_title+'</a></li>';            
          });
          html += '</ul>';
          $('#forum-search-result').removeClass('hide');
          $("#forum-search-result .content").html(html);
        }
        if (0==result.count){
          $('#forum-search-result').addClass('hide');
          if (!NewsSearchHaveResult){
            $('#highlight').addClass('hide');
            $('.help-block').removeClass('hide');
            $('.help-block').html('Informasi tentang "'+AKeyword+'" tidak ditemukan');
            
          }
        }else{
          TopicSearchHaveResult = true;
        }
        SetSearchView(false);
      }
    }
  });  
}

function PlaceToSearch(el){
  $("#query").val(el.text);
  $("#query").focus();
}
function SearchHistoryView(){
  if (SearchHistory.length === undefined || SearchHistory.length === null) {
    return
  }
  if (SearchHistory.length < 2){
    $('#history').addClass('hide');
    return;
  }
  $('#history').removeClass('hide');
  let html = "<ul>";
  for (var i = 0, len = SearchHistory.length; i < len; i++) {
    if (i > 15) 
      break;
    index = (SearchHistory.length - i) - 1;
    html += '<li><a href="#" class="search-history" onClick="PlaceToSearch(this);">';
    html += SearchHistory[index];
    html += "</a></li>";
  }
  html += "</ul>";
  $('#history .card-body').html(html);
}