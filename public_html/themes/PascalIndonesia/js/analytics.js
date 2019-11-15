window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'UA-151967332-1');

(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
  ga('create', 'UA-151967332-1', 'auto');
  ga('send', 'pageview');
    

$(function () {
  
  $(".main-header .navbar-nav a").click(function(event){
    var buttonText = $(this).text();
    //ga('send', 'event', 'Header-Navbar', 'click', buttonText);
    TrackEventGA('navbar', buttonText);
    //alert(buttonText);
  });

  $(".content a").click(function(event){
    var buttonText = $(this).text();
    //ga('send', 'event', 'content', 'click', buttonText);
    TrackEventGA('content', buttonText);
    //alert(buttonText);
  });

});


function TrackEventGA(Category, Action, Label, Value) {
  "use strict";
  if (typeof (_gaq) !== "undefined") {
      _gaq.push(['_trackEvent', Category, Action, Label, Value]);
  } else if (typeof (ga) !== "undefined") {
      ga('send', 'event', Category, Action, Label, Value);
  }
}
