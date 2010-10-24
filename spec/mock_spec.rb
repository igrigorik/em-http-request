require 'spec/helper'

describe 'em-http mock' do

  before(:all) do
    EventMachine::MockHttpRequest.activate!
  end

  after(:all) do
    EventMachine::MockHttpRequest.deactivate!
  end

  before(:each) do
    EventMachine::MockHttpRequest.reset_registry!
    EventMachine::MockHttpRequest.reset_counts!
  end

  it "should serve a fake http request from a proc" do
    EventMachine::HttpRequest.register('http://www.google.ca:80/', :get) { |req|
      req.response_header.http_status = 200
      req.response_header['SOME_WACKY_HEADER'] = 'WACKY_HEADER_VALUE'
      req.response = "Well, now this is fun."
    }
    EM.run {
      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.errback { fail }
      http.callback {
        http.response_header.status.should == 200
        http.response_header['SOME_WACKY_HEADER'].should == 'WACKY_HEADER_VALUE'
        http.response.should == "Well, now this is fun."
        EventMachine.stop
      }
    }

    EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
  end

  it "should serve a fake http request from a proc with raw data" do
    EventMachine::HttpRequest.register('http://www.google.ca:80/', :get) { |req|
      req.receive_data(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'google.ca')))
    }
    EM.run {
      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.errback { fail }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == File.read(File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'), :encoding => 'ISO-8859-1').split("\r\n\r\n", 2).last
        http.response.encoding.to_s.should == 'ISO-8859-1'
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
        EventMachine.stop
      }
    }
  end

  it "should serve a fake http request from a file" do
    EventMachine::HttpRequest.register_file('http://www.google.ca:80/', :get, {}, File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'))
    EM.run {

      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.errback { fail }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == File.read(File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'), :encoding => 'ISO-8859-1').split("\r\n\r\n", 2).last
        http.response.encoding.to_s.should == 'ISO-8859-1'
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
        EventMachine.stop
      }
    }
  end

  it "should serve a fake http request from a string" do
    data = <<-HEREDOC
HTTP/1.0 200 OK
Date: Mon, 16 Nov 2009 20:39:15 GMT
Expires: -1
Cache-Control: private, max-age=0
Content-Type: text/html; charset=ISO-8859-1
Set-Cookie: PREF=ID=9454187d21c4a6a6:TM=1258403955:LM=1258403955:S=2-mf1n5oV5yAeT9-; expires=Wed, 16-Nov-2011 20:39:15 GMT; path=/; domain=.google.ca
Set-Cookie: NID=28=lvxxVdiBQkCetu_WFaUxLyB7qPlHXS5OdAGYTqge_laVlCKVN8VYYeVBh4bNZiK_Oan2gm8oP9GA-FrZfMPC3ZMHeNq37MG2JH8AIW9LYucU8brOeuggMEbLNNXuiWg4; expires=Tue, 18-May-2010 20:39:15 GMT; path=/; domain=.google.ca; HttpOnly
Server: gws
X-XSS-Protection: 0
X-Cache: MISS from .
Via: 1.0 .:80 (squid)
Connection: close

<!doctype html><html><head><meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"><title>Google</title><script>window.google={kEI:"eLgBS4LROqCQedKVvfUL",kEXPI:"17259,21329,21516,22107",kCSI:{e:"17259,21329,21516,22107",ei:"eLgBS4LROqCQedKVvfUL"},kHL:"en",time:function(){return(new Date).getTime()},log:function(b,d,c){var a=new Image,e=google,g=e.lc,f=e.li;a.onerror=(a.onload=(a.onabort=function(){delete g[f]}));g[f]=a;c=c||"/gen_204?atyp=i&ct="+b+"&cad="+d+"&zx="+google.time();a.src=c;e.li=f+1},lc:[],li:0};
window.google.sn="webhp";window.google.timers={load:{t:{start:(new Date).getTime()}}};try{}catch(b){}window.google.jsrt_kill=1;
var _gjwl=location;function _gjuc(){var e=_gjwl.href.indexOf("#");if(e>=0){var a=_gjwl.href.substring(e);if(a.indexOf("&q=")>0||a.indexOf("#q=")>=0){a=a.substring(1);if(a.indexOf("#")==-1){for(var c=0;c<a.length;){var d=c;if(a.charAt(d)=="&")++d;var b=a.indexOf("&",d);if(b==-1)b=a.length;var f=a.substring(d,b);if(f.indexOf("fp=")==0){a=a.substring(0,c)+a.substring(b,a.length);b=c}else if(f=="cad=h")return 0;c=b}_gjwl.href="/search?"+a+"&cad=h";return 1}}}return 0}function _gjp(){!(window._gjwl.hash&&
window._gjuc())&&setTimeout(_gjp,500)};
window._gjp && _gjp()</script><style>td{line-height:.8em;}.gac_m td{line-height:17px;}form{margin-bottom:20px;}body,td,a,p,.h{font-family:arial,sans-serif}.h{color:#36c;font-size:20px}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{font:17px arial,sans-serif;margin-bottom:.2em;vertical-align:bottom;}input{font-family:inherit}.lsb,.gac_sb{font-size:15px;height:1.85em!important;margin:.2em;}#gbar{height:22px}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}#guser{padding-bottom:7px !important;text-align:right}#gbar,#guser{font-size:13px;padding-top:1px !important}@media all{.gb1,.gb3{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb3,a.gb4{color:#00c !important}.gb3{text-decoration:none}</style><script>google.y={};google.x=function(e,g){google.y[e.id]=[e,g];return false};</script></head><body bgcolor=#ffffff text=#000000 link=#0000cc vlink=#551a8b alink=#ff0000 onload="document.f.q.focus();if(document.images)new Image().src='/images/nav_logo7.png'" topmargin=3 marginheight=3><textarea id=csi style=display:none></textarea><div id=gbar><nobr><b class=gb1>Web</b> <a href="http://images.google.ca/imghp?hl=en&tab=wi" class=gb1>Images</a> <a href="http://video.google.ca/?hl=en&tab=wv" class=gb1>Videos</a> <a href="http://maps.google.ca/maps?hl=en&tab=wl" class=gb1>Maps</a> <a href="http://news.google.ca/nwshp?hl=en&tab=wn" class=gb1>News</a> <a href="http://groups.google.ca/grphp?hl=en&tab=wg" class=gb1>Groups</a> <a href="http://mail.google.com/mail/?hl=en&tab=wm" class=gb1>Gmail</a> <a href="http://www.google.ca/intl/en/options/" class=gb3><u>more</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><a href="/url?sa=p&pref=ig&pval=3&q=http://www.google.ca/ig%3Fhl%3Den%26source%3Diglk&usg=AFQjCNG2Kt7TgMZuV7Fl3FeeTOmTWMvggA" class=gb4>iGoogle</a> | <a href="/preferences?hl=en" class=gb4>Search settings</a> | <a href="https://www.google.com/accounts/Login?hl=en&continue=http://www.google.ca/" class=gb4>Sign in</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div><center><br clear=all id=lgpd><img alt="Google" height=110 src="/intl/en_ca/images/logo.gif" width=276 id=logo onload="window.lol&&lol()"><br><br><form action="/search" name=f><table cellpadding=0 cellspacing=0><tr valign=top><td width=25%>&nbsp;</td><td align=center nowrap><input name=hl type=hidden value=en><input name=source type=hidden value=hp><input type=hidden name=ie value="ISO-8859-1"><input autocomplete="off" maxlength=2048 name=q size=55 class=lst title="Google Search" value=""><br><input name=btnG type=submit value="Google Search" class=lsb><input name=btnI type=submit value="I'm Feeling Lucky" class=lsb></td><td nowrap width=25% align=left><font size=-2>&nbsp;&nbsp;<a href=/advanced_search?hl=en>Advanced Search</a><br>&nbsp;&nbsp;<a href=/language_tools?hl=en>Language Tools</a></font></td></tr><tr><td align=center colspan=3><font size=-1><span style="text-align:left">Search: <input id=all type=radio name=meta value="" checked><label for=all> the web </label> <input id=cty type=radio name=meta value="cr=countryCA"><label for=cty> pages from Canada </label> </span></font></td></tr></table></form><br><font size=-1>Google.ca offered in: <a href="http://www.google.ca/setprefs?sig=0_XtMil90_yvnNEW8dIglASaHCVhU=&hl=fr">fran?ais</a> </font><br><br><br><font size=-1><a href="/intl/en/ads/">Advertising&nbsp;Programs</a> - <a href="/services/">Business Solutions</a> - <a href="/intl/en/about.html">About Google</a> - <a href="http://www.google.com/ncr">Go to Google.com</a></font><p><font size=-2>&copy;2009 - <a href="/intl/en/privacy.html">Privacy</a></font></p></center><div id=xjsd></div><div id=xjsi><script>if(google.y)google.y.first=[];if(google.y)google.y.first=[];google.dstr=[];google.rein=[];window.setTimeout(function(){var a=document.createElement("script");a.src="/extern_js/f/CgJlbhICY2EgACswCjhBQB0sKzAOOAksKzAYOAQsKzAlOMmIASwrMCY4BywrMCc4Aiw/n_sssePDGvc.js";(document.getElementById("xjsd")||document.body).appendChild(a)},0);
;google.y.first.push(function(){google.ac.b=true;google.ac.i(document.f,document.f.q,'','')});google.xjs&&google.j&&google.j.xi&&google.j.xi()</script></div><script>(function(){
function a(){google.timers.load.t.ol=(new Date).getTime();google.report&&google.timers.load.t.xjs&&google.report(google.timers.load,google.kCSI)}if(window.addEventListener)window.addEventListener("load",a,false);else if(window.attachEvent)window.attachEvent("onload",a);google.timers.load.t.prt=(new Date).getTime();
})();
    HEREDOC
    EventMachine::HttpRequest.register('http://www.google.ca:80/', :get, {}, data)
    EventMachine.run {

      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.errback { fail }
      http.callback {
        http.response.should == data.split("\n\n", 2).last
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
        EventMachine.stop
      }
    }

  end

  it "should serve a fake failing http request" do
    EventMachine::HttpRequest.register('http://www.google.ca:80/', :get, {}, :fail)
    error = false

    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.callback {
        EventMachine.stop
        fail
      }
      http.errback {
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
        EventMachine.stop
      }
    }

  end

  it "should distinguish the cache by the given headers" do
    EventMachine::HttpRequest.register_file('http://www.google.ca:80/', :get,  {:user_agent => 'BERT'}, File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'))
    EventMachine::HttpRequest.register_file('http://www.google.ca:80/', :get, {}, File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'))
    EM.run {
      http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      http.errback { fail }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == File.read(File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'), :encoding => 'ISO-8859-1').split("\r\n\r\n", 2).last
        http.response.encoding.to_s.should == 'ISO-8859-1'
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {}).should == 1
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {:user_agent => 'BERT'}).should == 0
        EventMachine.stop
      }
    }

    EM.run {
      http = EventMachine::HttpRequest.new('http://www.google.ca/').get({:head => {:user_agent => 'BERT'}})
      http.errback { fail }
      http.callback {
        http.response_header.status.should == 200
        http.response.should == File.read(File.join(File.dirname(__FILE__), 'fixtures', 'google.ca'), :encoding => 'ISO-8859-1').split("\r\n\r\n", 2).last
        http.response.encoding.to_s.should == 'ISO-8859-1'
        EventMachine::HttpRequest.count('http://www.google.ca:80/', :get, {:user_agent => 'BERT'}).should == 1
        EventMachine.stop
      }
    }

  end

  it "should raise an exception if pass-thru is disabled" do
    EventMachine::HttpRequest.pass_through_requests = false
    EventMachine.run {
      proc {
        http = EventMachine::HttpRequest.new('http://www.google.ca/').get
      }.should raise_error
      EventMachine.stop
    }
  end
end
