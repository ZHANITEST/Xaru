/**
 *
 * [     xaru     ]
 *
 * Copyleft:
 * 2017 ZHANITEST(zhanitest.egloos.com)
 *
 * License:
 * Distributed under the terms of the 'LGPL v2' license.
 *
 */
module xaru;

import std.outbuffer;
import std.file;
import std.stdio;
import std.process;
static import std.uri;
static import std.net.curl;
static import re = std.regex;
import std.regex:ctRegex,regex;
import std.conv:to,text;
import std.random;
import std.string:indexOf;
import std.uni:toLower;
import std.format:formattedWrite;
import std.algorithm:sort;
import std.algorithm.iteration:map;
import std.array:array,replace,split,join,appender;
import std.parallelism:totalCPUs,parallel;
import core.thread:Thread, dur;

import requests;
import libdominator;

// 디버깅용 벤치마크
debug{ import std.datetime:benchmark; }

/**
 * 만화 카테고리 목록
 * (단편, 주간 , 격주 등등...)
 */
string[] CategoryList = [
	"단편", "주간", "격주", "월간", "격월/비정기",
	"단행본", "완결", "붕탁", "와이!",
	"오토코노코+엔솔로지", "여장소년+엔솔로지", "오토코노코타임", "붕탁+완결"
];

/**
 * 만화 카테고리 식별번호
 */
enum CategoryID{
	SHORT		= 27, /// 단편
	WEEK		= 28, /// 주간
	WEEK1		= 29, /// 격주
	MONTH		= 30, /// 월간
	MONTH1		= 31, /// 격월/비정기
	ONCE		= 32, /// 단행본
	END			= 33, /// 완결
	ANG			= 34, /// 붕탁
	Y			= 35, /// 와이!
	OTOKONOKO	= 36, /// 오토코노코+엔솔로지
	SHEMALE		= 37, /// 여장소년+엔솔로지
	OTOKONOKO1	= 38, /// 오토코노코타임
	ANG_END		= 39  /// 붕탁+완결
}

/**
 * 만화 카테고리를 상수로 변환
 */
public CategoryID str2id(string id){
	CategoryID[string] dic = [
		"주간":CategoryID.WEEK,
		"격주":CategoryID.WEEK1,
		"월간":CategoryID.MONTH,
		"격월/비정기":CategoryID.MONTH1,
		"단행본":CategoryID.ONCE,
		"완결":CategoryID.END,
		"단편":CategoryID.SHORT,
		"붕탁":CategoryID.ANG,
		"와이!":CategoryID.Y,
		"오토코노노코+엔솔로지":CategoryID.OTOKONOKO,
		"여장소년+엔솔로지":CategoryID.SHEMALE,
		"오토코노코타임":CategoryID.OTOKONOKO1,
		"붕탁+완결":CategoryID.ANG_END
	];
	return dic[id];
}
public string id2str(CategoryID id_enum){
	string result = "";
	switch( id_enum ){
	case CategoryID.WEEK:
		result = "주간";
		break;
	case CategoryID.WEEK1:
		result = "격주"; break;
	case CategoryID.MONTH:
		result = "월간"; break;
	case CategoryID.MONTH1:
		result = "격월/비정기"; break;
	case CategoryID.ONCE:
		result = "단행본"; break;
	case CategoryID.END:
		result = "완결"; break;
	case CategoryID.SHORT:
		result = "단편"; break;
	case CategoryID.ANG:
		result = "붕탁"; break;
	case CategoryID.Y:
		result = "와이!"; break;
	case CategoryID.OTOKONOKO:
		result = "오토코노노코+엔솔로지"; break;
	case CategoryID.SHEMALE:
		result = "여장소년+엔솔로지"; break;
	case CategoryID.OTOKONOKO1:
		result = "오토코노코타임"; break;
	case CategoryID.ANG_END:
		result = "붕탁+완결"; break;
	default:
		result = "주간"; break;
	}
	return result;
}

/**
 *	Headless 드라이버 타입
 */
deprecated enum BrowserType{
	PhantomJS, SlimerJS
}

/**
 * 만화 링크
 */
struct cartoonLink{
	uint id; // 만화 ID
	string title;
	string name; // 이름(~화)
	string url; // 주소
	
	/**
	 * 생성자
	 */ 
	this(uint id, string title, string name, string url){
		this.id = id;
		this.title = title;
		this.name = name;
		this.url = url;
	}
}

/**
 * 디렉토리 중복에 상관없이 생성
 */
void makeDir( string path ){
	string[] keywords = split(path, "/");
	string stack = "./";
	foreach(p; keywords){
		stack ~= stripSpecialChars(p)~"/";
		if( !exists(stack) )
			{ mkdir(stack); }
	}
}

/**
 * 입력받은 URL로부터 cURL을 이용해 HTML 가져오기
 */
string getRequest( string url, bool using_http_agent = false ){
	string html;
	auto rq = Request();
	if(using_http_agent){ // 헤더를 사용해야할 때...
		rq.addHeaders(["User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW6478) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.72 Safari/537.36"]);
	}
	Response rp = rq.get(url);
	html = to!string(rp.responseBody);
	return html;
}


/**
 * 특수문자 제거
 */
string stripSpecialChars( string text, string keyword=" " ){
	string result = text;
	string[] table = [ "/", ":", "*", "?", "<", ">", "|", "？" ];
	foreach( t; table ){
		result = result.replace(t, "");
	}
	return result;
}



/**
 * 회차 파싱
 */
cartoonLink[] scarpChapter(string url){
	cartoonLink[] links;
	string html = getRequest(url);
	
	// 제목 얻어오기
	auto rm = re.matchFirst( html, ctRegex!("<meta property=\"og:title\" content=\"(.+)\"/>") );
	string title = to!string(rm[1]);

	// DOM 오브젝트 생성
	Dominator dom = new Dominator(html);
	Node[] nodes = dom.filterDom("a");

	// cartoonLink의 첫번째 인수로 넣을 인덱스
	uint index = 0; 
	
	foreach(node; nodes){
		 // 노드들 중에 원하는 도메인 문자열이 들어간 노드만 사용
		foreach(ab; node.getAttributes()){
			string[] vs = ab.values;		// string key => string[] values
			string value;					// string value => eg. 나만이 없는 거리 3화

			// lambda
			auto x = (string keyword){
				foreach(v; vs)
					{ if(v.indexOf(keyword)>-1) {value=v; return true;} }
				return false;
			};

			// key=href면서, 해당 도메인(bool x())이 포함된 경우,
			if(ab.key=="href" && (x("yuncomics.com")||x("shencomics.com")||x("wasabisyrup.com")) ){
				auto removeTag = (string target){ return re.replaceAll(target, ctRegex!("<[^>]*>"), ""); };
				links ~= cartoonLink(index, title, removeTag(dom.getInner(node)), value);
				index += 1;
			}
		}
	}
	return links;
}



/**
 * Headless 브라우저 드라이버
 */
deprecated class SimpleWebDriver{
	protected:
		string url; // 주소
		BrowserType browserType; // 브라우저 타입
	
	private:
		string scriptFileName;
		string engineFileName;

	/**
	 * 생성자
	 */ 
	this( string url, BrowserType browser_type=BrowserType.PhantomJS ){
		// url 인수를 멤버변수로 복사
		this.url = url;

		// 브라우저 타입 정의
		this.browserType = browser_type;

		// 확장자 지정
		string ext = "";
		version(Windows) {
			ext = (this.browserType==BrowserType.PhantomJS) ? ".exe" : ".bat";
		}

		// PhantomJS 실행파일 정의 (기본값: phantomjs.exe )
		this.engineFileName = (this.browserType== BrowserType.PhantomJS) ? "phantomjs"~ext : "slimerjs"~ext;

		debug{
			writeln(this.engineFileName);
		}
	}

	/**
	 * 엔진 가지고 있는 지 확인
	 */
	bool haveYou(){
		if( std.file.exists(this.engineFileName) ) {
			return true;
		}
		else {
			return false;
		}
	}

	/**
	 * HTML을 얻어오는 스크립트 작성 / 실행 / 프로세싱
	 */
	string grab(){
		// 랜덤 5자리 생성
		this.scriptFileName = "grab-";
		
		// +++ foreach를 map으로 변경
		map!( x => this.scriptFileName~=to!string(x))( randomSample([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ], 5) );

		this.scriptFileName ~= ".js";

		// 스크립트 작성
		File fs = File( this.scriptFileName, "w" );
		string exit_string = (this.browserType==BrowserType.PhantomJS) ? "phantom.exit();" : "slimer.exit();";
		fs.write( "var webPage = require('webpage'); var page = webPage.create(); page.open('"~this.url~"', 'post', '478=qndxkr', function(status) { setTimeout(function(){ console.log( page.content); "~exit_string~" }, 300); });" );
		fs.close();

		// 프로세스 실행
		auto pid = pipeProcess(
			[this.engineFileName, this.scriptFileName],
			Redirect.all, null,
			Config.suppressConsole
		);
		scope(exit) wait(pid.pid);

		// 프로세스로 부터 출력내용을 문자열로 재작성
		string result = "";
		foreach(line; pid.stdout.byLine){
			result ~= line;
		}

		// 결과물이 없다면 에러
		if( result == "" ){
			throw new Exception("해당 주소로 HTML값을 읽어올 수 없습니다.");
			scope(failure) return result;
		}
		remove(this.scriptFileName);
		return result;
	}
}



/**
 * 만화 페이지
 */
struct cartoonPage{
	private:
		string hostingUrl;
		cartoonLink baseLink;
	/**
	 * 생성자
	 */
	public this(cartoonLink target){
		auto mr = re.matchFirst(target.url, ctRegex!("[shenyucomicswabrp]+.com"));
		this.hostingUrl = mr[0];
		this.baseLink = target;
	}

	/**
	 * 스크랩
	 */
	protected string[] getImageUrls(){
		string[] urls;
		string html = getRequest(baseLink.url);

		// 암호 걸린 만화일 경우
		if(html.indexOf("Protected")>-1){
			auto res = postContent(
				this.baseLink.url, queryParams("password", "qndxkr", "pass", "qndxkr")
			);
			OutBuffer buf = new OutBuffer();
			buf.write(res.data);
			html = buf.toString();
		}

		debug{
			if(html.indexOf("Protected")>-1){
				writeln("Protected Link:", this.baseLink);
			}
		}

		Dominator dom = new Dominator(html);
		Node[] nodes = dom.filterDom("img");

		foreach(node; nodes){
			foreach(ab; node.getAttributes()){
				string v = ab.values[0];
				if(v.indexOf("/storage/gallery/")>-1){
					urls ~= "http://"~this.hostingUrl~v;
				}
			}
		}

		// {임시} 조건 하나 더 검사...
		//	regex vs indexOf
		
		if(	urls[0].indexOf("jpg")<0 &&
			urls[0].indexOf("jpeg")<0&&
			urls[0].indexOf("JPG")<0 &&
			urls[0].indexOf("JPEG")<0 )
		{
			urls = null;
			
			// 패턴들
			string[] patthens = [
				"/storage/gallery/[A-z0-9-]+/[\\S_)(]+ [\\S_)(]+\\.[JjPpEeGg]+",
				"/storage/gallery/[A-z0-9-]+/[\\S_)( ]+\\.[JjPpEeGg]{3,4}"
			];

			foreach(p; patthens){
				auto r = re.matchAll(html, regex(p));
				if(r.empty==false){
					foreach(e; r)
						{ urls ~="http://"~this.hostingUrl~e[0]; }
				}
			}
		}
		return urls;
	}

	public void download(){
		string[string] dl_list;
		uint count = 0;
		foreach(imgurl; this.getImageUrls()){
			string path = "./download/"~stripSpecialChars(baseLink.title)~"/"~stripSpecialChars(baseLink.name)~"/";
			makeDir(path);
			auto n = std.array.appender!string();
			formattedWrite(n, "%.4d", count);
			dl_list[imgurl] = path~n.data~"_"~stripSpecialChars(split(imgurl,"/")[$-1]);
			count += 1;
		}

		// 병렬
		writeln("다운로드 시작: "~this.baseLink.name);
		foreach( imgurl; parallel(dl_list.keys) ){
			auto rq = Request();
			auto ds = rq.get(std.uri.encode(imgurl));
			std.file.write(dl_list[imgurl], ds.responseBody.data);
		}
		writeln("다운로드 완료: "~this.baseLink.name);
		writeln("______________________________________________________________________");
	}
}



/**
 * 마루마루 사이트 파싱 클래스
 *
 * Example
 * ------------------------------
 * auto site_bot = new MaruMaruPage("84968");
 * site_bot.search("블리치");
 * ------------------------------
 */
class MaruMaruPage{
	private:
		string id;
		string cookedHtmlText;
		string htmlText;
		string masterTag;

	/**
 	* 생성자
 	*/
	this( ulong id ) {
		this(to!string(id));
	}

	/**
	 * 생성자
	 */
	this( string comics_id ){
		// ID 저장
		this.id = comics_id;
		
		// 입력한 문자열이 숫자형태인지 검증
		auto result = re.match( comics_id, ctRegex!("^[\\d]+$") );
		if( result.empty() ){
			throw new Exception("옳바른 숫자 형식이 아닙니다.");
		}
		string id_number = result.front.hit();

		//id 가지고 주소 가지고 있기(this.htmlText)
		navigate("http://marumaru.in/b/manga/"~id_number);

		// 마스터 태그 선언(html의 태그,속성 한방에 지우는 표현식)
		//this.masterTag = "[!#A-z0-9=\"-:;,가-힣 \\.\\(\\)]";
		this.masterTag = "[!#A-z0-9가-힣=\"'-:;, \\.\\(\\)&]";
		this.cookedHtmlText = stripTags( stripBody(this.htmlText) );
	}

	/**
	 * 태그 지우기
	 */
	private string stripTags( string origin_text ){
		// 아예 필요없어서 제거해버리는 태그 정의
		string tags = [];
		
		string[] dont_need_words = [
			" *&nbsp; *",
			" *amp; *",
			"\n",
			"<br[/]*>"
		];

		// 앵커<a>를 제외한 html표준 태그 정의
		string[121] html_tags = [
			"h1", "h2", "h3", "h4", "h5", "h6", "abbr", "acronym", "address", "applet", "area", "article",
			"aside", "audio", "b", "base", "basefont", "bdi", "bdo", "big", "blockquote", "body", "br",
			"button", "canvas", "caption", "center", "cite", "code", "col", "colgroup", "datalist", "dd",
			"del", "details", "dfn", "dialog", "dir", "div", "dl", "dt", "em", "embed", "fieldset", "figcaption",
			"figure", "font", "footer", "form", "frame", "frameset", "head", "header", "hr", "html", "i", "iframe",
			"img", "input", "ins", "kbd", "keygen", "label", "legend", "li", "link", "main", "map", "mark", "menu",
			"menuitem", "meta", "meter", "nav", "noframes", "noscript", "object", "ol", "optgroup", "option", "output",
			"p", "param", "picture", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select",
			"small", "source", "span", "strike", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "textarea",
			"tfoot", "th", "thead", "time", "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"
		];
		
		string result_text = origin_text;

		//map!(tag=>dont_need_words[$]=" *</*"~tag~this.masterTag~"*> *")( html_tags );
		foreach( tag; html_tags ){
			dont_need_words ~= " *</*"~tag~this.masterTag~"*> *";
		}

		foreach( word; dont_need_words ){
			result_text = re.replaceAll(result_text, regex(word), "");
		}
		// 한번에 제거

		


		return result_text;
	}

	/**
	 * 주소로 이동
	 */
	private void navigate( string url ){
		this.htmlText = getRequest(url);
	}

	/**
	 * 본문만 따오기
	 */
	private string stripBody( string html_text ){
		// start_tag의 서식 정의
		immutable string format1 = "<div id=\"vContent\" class=\"content\">";
		immutable string format2 = "<div class=\"ctt_box\">";

		// end_tag 정의
		immutable string end_tag = "<div align=\"center\">\n<a href=";
		string start_tag;

		// class="content"가 검색됬는가?
		if( html_text.indexOf(format1) ){
			start_tag = format1;
		}
		// class="ctt_box"가 검색됬는가?
		else if( html_text.indexOf(format2) ){
			start_tag = format2;
		}
		// 이것도 저것도 검색이 안되는 경우
		else{ 
			throw new Exception("본문에서 만화주소 부분의 태그를 읽는데 실패했습니다.");
			scope(failure) return "";
		}

		// uint → auto ; LDC 1.1에서 ulong/uint 간의 타입 선언 차이로 이렇게 해야 빌드 됨.
		auto x = html_text.indexOf(start_tag) + start_tag.length;
		auto y = html_text[x..$].indexOf(end_tag);

		if(x < x+y){
			return html_text[x..x+y];
		}
		else if(x+y < x){
			debug{
				writeln("[stripBody] - Out of range...");
				write("x:"); writeln(x);
				write("y:"); writeln(y);	
			}
			throw new Exception("본문에서 만화주소 부분의 위치(범위)를 읽는데 실패했습니다.");
		}
		return "";
	}

	/**
	 * 해당 키워드로 만화 검색 후 결과 제공(수정 예정)
	 */
	string[string][] search( string keyword, bool with_url=true ){
		string[string][] result;
		navigate("http://marumaru.in/?r=home&mod=search&keyword="~keyword~"&x=0&y=0");
		// 패턴매칭 서식
		// [0]: 모든 문자열, [1]: /b/manga/ID, [2]: ID, [3]: 만화 제목
		string patthen = "<a href=\"(\\/b\\/manga\\/([\\d]+))\" class=\"subject\">[\n<tablerd>]+<span class=\"thumb\">.+[\n<\\/tablerd>]+<div class=\"sbjbox\">\n<b>(.+)<\\/b>";
		auto match_result = re.matchAll( this.htmlText, regex(patthen) );

		foreach( element; match_result ){
			result ~= [
				element[3] : with_url ? element[1]:element[2]
			];
		}
		return result;
	}

	/**
	 * 만화제목 얻기
	 */
	string getTitle(){
		auto re_result = re.match( this.htmlText, ctRegex!(r"<h1>(.+)<\/h1>") );
		string title;
		
		foreach( e; re_result )
			{ title = e[1]; }

		// <h1>~</h1> 태그 안에 또다른 태그가 존재한다면,
		if( title.indexOf("<") != -1 || title.indexOf(">") != -1 ){
			title = re.replaceAll( title, ctRegex!(" *</*[fontspa]+ *[stycolrface =\"#\\d\\w,:;\\.\\-\\(\\)]*> *"), "" );
		}
		return title;
	}

	/**
	 * 카테고리 별로 만화 목록 가져오기(수정 예정)
	 */
	deprecated string[string] getCartoonList( CategoryID category_enum ){
		string id = to!string(category_enum);
		string category = to!string(id2str(category_enum));
		
		string base_url = "www.marumaru.in/?c=1/"~id;
		string[string] cartoon_list; // 인덱스 리스트
		ushort page_count; // 페이지 수
		
		// 이 카테고리의 페이지는 얼마나 되느뇨?
		string html = getRequest( base_url );

		// match_result TO array
		auto match_result = re.matchAll( html, ctRegex!(r">([\d]+)</[span]{1,4}>") );
		string[] temp;
		map!(x => temp~=x[1])( array(match_result) );
		sort(temp);
		
		page_count = to!ushort( temp[temp.length-1] );

		// 페이지 별로 파싱 (1, 2, 3 페이지...)
		foreach( page; temp ){
			html = getRequest( base_url~"&cat="~category~"&p="~page );
			auto urls_match = re.matchAll( html,
				ctRegex!(r"uid=([\d]+).><span class=.cat.>[\S ]+<\/span>([\d\S ]+)<\/a>")
			);
			map!(e=>cartoon_list[e[2]]~=e[1])( urls_match );
		}
		return cartoon_list;
	}

	/**
	* 만화 회차 얻기
	*/
	cartoonLink[] getChapters(){
		// 만화 호스팅 도메인들
		string[] domains = [
			"shencomics.com",
			"wasabisyrup.com",
			"yuncomics.com"
		];

		// URL이랑 회차 검색을 위한 표현식생성
		string patthen = "<a"~this.masterTag~"*(http://[wblog\\.]*["~domains.join()~"]+/archives/[_0-9A-z-]+)\""~this.masterTag~"*>(.+)";

		// 패턴 객체 생성
		auto regex_object = regex(patthen);

		// 생성자에서 치환된 this.textBody로 부터 배열생성(구분자:</a>)
		uint num = 0;
		cartoonLink[] links; // 결과물 담을 배열
		foreach( raw_chapter_url; split(this.cookedHtmlText, "</a>") ){
			// 매치( 검색 문자는 url과 회차 제목이기 때문에 matchAll 사용함 )
			auto result_object = re.matchAll( raw_chapter_url, regex_object );
			
			string url = result_object.front[1];
			string inner = result_object.front[2];

			// 비어있지 않다면 cartoonLink 구조체 저장
			if( url!="" && inner!="" ){
				cartoonLink link;
				
				link.title = this.getTitle();
				link.id = to!uint(this.id);
				link.name = this.stripTags(inner);
				link.url = url;

				links ~= link;
			}
		}
		// +++ 링크가 비어있을 때의 예외추가
		if( links.length == 0 ){
			string msg = "만화 회차와 호스팅 URL를 얻어 오는데 실패했습니다. REF[ID#"~this.id~"]";
			msg ~= "::"~this.cookedHtmlText;
			throw new Exception(msg);
			scope(failure) return links;
		}
		return links;
	}
	
	/**
	 * 원래의 HTML 코드 얻기
	 */
	string getText(){
		return this.htmlText;
	}
}



/**
 * 리팩토링 피처들
 */
//----------------------------------------------------------------------
//
// #1. HTML 얻어오기: getRequest 재작성
//
//----------------------------------------------------------------------
unittest{
	string url = "http://marumaru.in/b/manga/41079"; // 나만이 없는 거리:41079
	string html = getRequest(url);
	assert(html.indexOf("나만이 없는 거리")+1, "#1 getRequest() → 빈 문자열임"); // -1 + 1 = 0
}


//----------------------------------------------------------------------
//
// #2. #1에서 긁어온 HTML에서, 회차만 파싱
//
//----------------------------------------------------------------------
unittest{
	string url = "http://marumaru.in/b/manga/41079"; // 나만이 없는 거리:41079
	cartoonLink[] links = scarpChapter(url);
	foreach(l; links){
		// 회차 이름에 HTML태그가 남아있는 지 검사
		assert(l.name.indexOf("<")==-1, "#2 태그검사 오류(<)");
		assert(l.name.indexOf(">")==-1, "#2 태그검사 오류(>)");
	}
	// 링크 파싱 갯수가 0이 아니여야 함 == 파싱성공
	assert(links.length, "#2 링크 파싱개수가 0임");
}


//----------------------------------------------------------------------
//
// #3. #2에서 긁어온 회차 URL로 부터 이미지 URL 따오기
//
//----------------------------------------------------------------------
unittest{
	string url = "http://marumaru.in/b/manga/41079"; // 나만이 없는 거리:41079
	cartoonLink[] links = scarpChapter(url);

	// 테스트 목적이므로 맨 첫번째 것만 가져오도록..
	cartoonPage cp = cartoonPage(links[0]);
	string[] img_urls = cp.getImageUrls();
	assert(img_urls.length+1, "#3 이미지 URL 파싱개수가 0임");
}


//----------------------------------------------------------------------
//
// #4. #3에서 만든 cartoonPage 구조체를 가지고 다운로드(NOT API, for ConsoleApp)
//
//----------------------------------------------------------------------
unittest{
	string url = "http://marumaru.in/b/manga/41079"; // 나만이 없는 거리:41079
	cartoonLink[] links = scarpChapter(url);

	// 테스트 목적이므로 맨 첫번째 것만 가져오도록..
	cartoonPage cp = cartoonPage(links[0]);
	//cp.download();
}


//----------------------------------------------------------------------
//
// #5. 비밀번호 처리
//
//----------------------------------------------------------------------
unittest{
	//string url = "http://marumaru.in/b/manga/206969"; // 서른살 처녀와 인기많은 어쩌구(걍 17금 만화 아무거나)
	string url = "http://wasabisyrup.com/archives/mzemO5HX-HE";

	//cartoonLink[] links = scarpChapter(url);
	//cartoonPage cp = cartoonPage(links[0]);
	string html = getRequest(url);
	
	if(html.indexOf("Protected")>-1){
		writeln("보호!");
		auto content = postContent(url, queryParams("password", "qndxkr", "pass", "qndxkr"));
		OutBuffer buf = new OutBuffer();
		buf.write(content.data);
		writeln(buf.toString());
	}
}