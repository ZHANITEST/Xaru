//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
//	Xaru.d
//	License: LGPL v2
//
//	By ZHANITEST( * zhanitest.egloos.com )
//
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
module xaru;
import std.net.curl;
import std.regex;
import std.stdio;
import std.conv;
import std.uri:encode;
import std.algorithm;
import std.string:indexOf;
import std.file;
import std.process;
import std.array:replace;
//--------------------------------------------------------------------------------
//
// - [ 상수 정의; ] -
//
//--------------------------------------------------------------------------------
//
// @ 카테고리 리스트<const, immutable 금지 ; XaruGUI에 들어갈 것.>
//
string[] CategoryList = ["단편", "주간", "격주", "월간", "격월/비정기", "단행본", "완결", "붕탁", "와이!", "오토코노코+엔솔로지", "여장소년+엔솔로지", "오토코노코타임", "붕탁+완결"];
//
// @ 마루마루 만화 페이지의 타입
//
enum CartoonPageType{
	MANGA,
	MANGAUP,
	AUTO
}
//
// @ 만화 카테고리들
//
enum Category{
	SHORT		= ["단편", "27"],
	WEEK		= ["주간", "28"],
	WEEK1		= ["격주", "29"],
	MONTH		= ["월간", "30"],
	MONTH1		= ["격월/비정기", "31"],
	ONCE		= ["단행본","32"],
	END			= ["완결", "33"],
	ANG			= ["붕탁", "34"],
	Y			= ["와이!", "35"],
	OTOKONOKO	= ["오토코노코+엔솔로지," "36"],
	SHEMALE		= ["여장소년+엔솔로지", "37"],
	OTOKONOKO1	= ["오토코노코타임", "38"],
	ANG_END		= ["붕탁+완결", "39"]
}

//
// @ 모바일 에이전트(일단 안씀)
//
/*
immutable string[string] MobileAgent = [
	"Apple_IPhone":"Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/1A542a Safari/419.3",
	"Apple_IPad":"Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B367 Safari/531.21.10",

	"BlackBerry_9700Bold":"BlackBerry9700/5.0.0.423 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/100",
	
	"Android SDK 1.5r3":"Mozilla/5.0 (Linux; U; Android 1.5; de-; sdk Build/CUPCAKE) AppleWebkit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
    "Nexus One":"Mozilla/5.0 (Linux; U; Android 2.1-update1; en-us; Nexus One Build/ERE27) AppleWebkit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17",

    "HTC_Legend":"Mozilla/5.0 (Linux; U; Android 2.1-update1; fr-fr; desire_A8181 Build/ERE27) AppleWebKit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17",
    "HTC_Hero":"Mozilla/5.0 (Linux; U; Android 1.5; en-za; HTC Hero Build/CUPCAKE) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
    "HTC_Tattoo":"Mozilla/5.0 (Linux; U; Android 1.6; en-us; HTC_TATTOO_A3288 Build/DRC79) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
    "HTC_Magic":"Mozilla/5.0 (Linux; U; Android 1.5; en-dk; HTC Magic Build/CUPCAKE) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
	"HTC_EVO4G":"Mozilla/5.0 (Linux; U; Android 2.1-update1; en-us; Sprint APA9292KT Build/ERE27) AppleWebKit/530.17 (KHTML, like Gecko)",

	"SAMSUNG_i7500Galaxy":"Mozilla/5.0 (Linux; U; Android 1.5; de-de; Galaxy Build/CUPCAKE) AppleWebkit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
	"SAMSUNG_SHVE250S":"Mozilla/5.0 (Linux; U; Android 4.4.2; ko-kr; SHV-E250S Build/KOT49H) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"
];*/

//--------------------------------------------------------------------------------
//
// - [ 상수 정의;끝 ] -
//
//--------------------------------------------------------------------------------





//--------------------------------------------------------------------------------
//
// - [ 유틸리티 함수 모음; ] -
//
//--------------------------------------------------------------------------------

//
// @ makedir; 디렉토리 중복에 상관없이 생성
//
void makedir( string path ){ if( !exists(path) ){ mkdir(path); } }

//
// @ log; 배열을 텍스트파일로 출력
//
void log( string filename, string body_ ){
	debug{
		auto f = new File( "[debug]"~filename, "w"); f.write( body_ ); f.close();
	}
}

//
// @ log; 배열을 텍스트파일로 출력
//
void logArray( string file_name, string[] output ){
	File f = File("[debug]"~file_name, "w");
	foreach( line; output ) { f.writeln(line); }
	f.close();
}

//
// @ ezUniq; 배열로부터 중복제거
//
string[] ezUniq(string[] ori)
{
	string[] fix; foreach( e; ori ){ import std.algorithm.searching:canFind; if( !canFind(fix, e) ){ fix~=e; } } return fix;
}

//
// @ ezFilter; 해당 문자열의 요소를 전부 지움!
//
string[] ezFilter( string[] array, string keyword )
{
	string[] temp = []; if(array.length>0){ foreach( e; array) { if( indexOf(e, keyword)== -1 ){temp~=e;} } } return temp;
}

//
// @ GET; 입력받은 URL로부터 cURL을 이용해 HTML 가져오기
//
string GET( string url, bool using_http_agent = false ){
	string html;
	try
	{
		// 에이전트 이용 여부
		if( using_http_agent )
		{
			auto http = HTTP(url);
			http.setUserAgent( "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.72 Safari/537.36" );
			html = cast(string)get(url, http);
		}
		else if( !using_http_agent )
		{
			html = cast(string)get(url); }
		}
	catch(CurlException e)
		{ return e.msg; }
	return html;
}

//
// @ stripSpecialChars; 특수문자 제거 함수
//
string stripSpecialChars( string body_ ){
	string result = body_;
	string[] table = [ "/", ":", "*", "?", "<", ">", "|" ];
	foreach( e; table ){
		result = result.replace( e, "_" );
	}
	return result;
}

//
// @ 윈도우 CMD에서 한글출력하기
//
version(Windows){
	extern(C) int setlocale(int, char*);
	static this(){
		core.stdc.wchar_.fwide(core.stdc.stdio.stdout, 1);
		setlocale(0, cast(char*)"korea");
	}
}

//
// @ 만화 카테고리들
//
public Category str2cat( string obj ){
	switch( obj ){
		case "주간":
			return Category.WEEK; break;
		case "격주":
			return Category.WEEK1; break;
		case "월간":
			return Category.MONTH; break;
		case "격월/비정기":
			return Category.MONTH1; break;
		case "단행본":
			return Category.ONCE; break;
		case "완결":
			return Category.END; break;
		case "단편":
			return Category.SHORT; break;
		case "붕탁":
			return Category.ANG; break;
		case "와이!":
			return Category.Y; break;
		case "오토코노노코+엔솔로지":
			return Category.OTOKONOKO; break;
		case "여장소년+엔솔로지":
			return Category.SHEMALE; break;
		case "오토코노코타임":
			return Category.OTOKONOKO1; break;
		case "붕탁+완결":
			return Category.ANG_END; break;
		default:
			return Category.WEEK; break;
	}
}
//--------------------------------------------------------------------------------
//
// - [ 유틸리티 함수 모음;끝 ] -
//
//--------------------------------------------------------------------------------





//--------------------------------------------------------------------------------
//
// - [ PhantomJS 드라이버 클래스 ] -
//
//--------------------------------------------------------------------------------
class Ghost{
	public string Url;
	public string FileName;

	// 실행되는 운영체제의 기본값은 windows
	this( string url, string os="windows", string engine_file_name="phantomjs" )
	{
		// url 인수를 멤버변수로 복사
		this.Url = url;

		// 확장자 정의
		string ext="";
		if( os == "windows") { ext = ".exe";}

		// PhantomJS 실행파일 정의 (기본값: phantomjs.exe )
		this.FileName = engine_file_name~ext;
	}

	// PhantomJS 파일이 존재하는가?
	bool hadTomb(){
		if( std.file.exists(this.FileName) )
		{
			return true;
		}
		else
		{ return false; }
	}

	// HTML을 얻어오는 스크립트 작성 & 실행 & 프로세싱
	string Grab(){
		// 스크립트 작성
		File f = File("grab.js", "w");
		f.write("var f = require('fs'); var webPage = require('webpage');var page = webPage.create(); page.open('"~this.Url~"', function(status) {setTimeout(function(){ console.log(page.content);phantom.exit();}, 30000);});");
		f.close();

		// 프로세스 실행
		auto pid = pipeProcess(["phantomjs", "grab.js"], Redirect.all, null, Config.suppressConsole);
		scope(exit) wait(pid.pid);

		// 프로세스로 부터 출력내용을 문자열로 재작성
		string result = "";
		foreach(line; pid.stdout.byLine){
			result ~= line;
		}
		return result;
	}

	// 소멸자
	~this()
	{
	}
}
//--------------------------------------------------------------------------------
//
// - [ PhantomJS 드라이버 클래스;끝 ] -
//
//--------------------------------------------------------------------------------





//--------------------------------------------------------------------------------
//
// - [ 마루마루 사이트 파싱 클래스; ] -
//
//--------------------------------------------------------------------------------
class MaruMaru{
	private string HTML;
	private string BASE_URl;
	void navigate( string url ){
		this.HTML = GET(url);
	}

	//
	// 해당 키워드로 만화 검색하여 제공
	//
	string[string][] search( string keyword, bool with_url=true ){
		string[string][] result;
		navigate("http://marumaru.in/?r=home&mod=search&keyword="~keyword~"&x=0&y=0");
		// 패턴매칭 서식
		// [0]: 모든 문자열, [1]: /b/manga/ID, [2]: ID, [3]: 만화 제목
		string patthen = "<a href=\"(\\/b\\/manga\\/([\\d]+))\" class=\"subject\">[\n<tablerd>]+<span class=\"thumb\">.+[\n<\\/tablerd>]+<div class=\"sbjbox\">\n<b>(.+)<\\/b>";
		auto match_result = matchAll( this.HTML, regex(patthen) );

		foreach( element; match_result ){
			result ~= [
				element[3] : with_url ? element[1]:element[2]
			];
		}
		return result;
	}



	//
	// 만화 목록 가져오기
	//
	string[string] getCartoonList( Category cat_ ){
		auto cat = cat_;
		string id		= cat[1]; string category = cat[0];
		string base_url = "www.marumaru.in/?c=1/"~id;
		string[string] CartoonList;	// 인덱스 리스트
		uint page_count;			// 페이지 수
		
		// 이 카테고리의 페이지는 얼마나 되느뇨?
		string html = GET( base_url );

		// match_result TO array
		auto match_result = matchAll( html, regex(r">([\d]+)</[span]{1,4}>") );
		string[] temp;
		foreach( element; match_result ){ temp ~= element[1]; }
		sort( temp );
		page_count = to!uint( temp[temp.length-1] );
		
		// 페이지 별로 파싱 (1, 2, 3 페이지...)
		foreach( page; temp ){
			html = GET( base_url~"&cat="~category~"&p="~page );
			auto urls_match = matchAll( html, regex( r"uid=([\d]+).><span class=.cat.>[\S ]+<\/span>([\d\S ]+)<\/a>"));
			foreach( element; urls_match ){
				CartoonList[ element[2] ] ~= element[1] ;
			}
		}
		return CartoonList;
	}
}

//--------------------------------------------------------------------------------
//
// - [ 마루마루 사이트 파싱 클래스;끝 ] -
//
//--------------------------------------------------------------------------------





//--------------------------------------------------------------------------------
//
// - [ 마루마루 만화클래스; ] -
//
//--------------------------------------------------------------------------------
class Cartoon{
	private string[string][] LIST;
	private string HTML;
	private CartoonPageType TYPE;

	// 어떤 작품의 회차 매칭 패턴
	private immutable string CHAPTER_MATCHING_PATTHEN;

	public string ID;
	public string URL;

	//
	// @ 생성자
	//
	this( string id, bool load=true ){
		this.LIST = null;
		this.ID = id;
		this.CHAPTER_MATCHING_PATTHEN = "href=\"(http://[wblog\\.]*[sheyuncomiwabirp]{9,11}.com/archives/[0-9A-z-]+)\">(.+)</a>";

		// 그냥 magna로 정의
		string page_type = "manga";
		this.TYPE = CartoonPageType.MANGA;
		
		try
		{
			// URL과 HTML을 요청 후 저장
			this.URL="http://marumaru.in/b/"~page_type~"/"~this.ID;
			this.HTML = GET(this.URL);
		}
		// cURL 에러가 발생 시 ... 
		catch( std.net.curl.CurlException e )
		{
			if( page_type == "magnaup")
				{ this.URL="http://marumaru.in/b/manga/"~this.ID; this.HTML = GET(this.URL); }
			else if( page_type == "manga")
				{ this.URL="http://marumaru.in/b/mangaup/"~this.ID; this.HTML = GET(this.URL);  }
		}
		finally
		{
			if( this.HTML.indexOf( "<div id=\"vContent\"" ) == -1 ){
				throw new Error("해당 만화의 HTML를 잃어올 수 없습니다. 마루마루 사이트 자체의 문제인지 확인해보시고 다시 시도해주세요.\n(Can't not open http://marumaru.in/b/"~page_type~"/"~id~")\n==================================================\n참조:\n"~this.HTML);
			}
			// 미리 읽기가 등록되어 있다면...
			else if( load )
			{
				this.LIST = getList();
			}
		}
	}

	//
	// @ 본문만 따오기(vContent)
	//
	private string stripBody(){
		// start_tag의 서식 정의
		immutable string format1 = "<div id=\"vContent\" class=\"content\">";
		immutable string format2 = "<div class=\"ctt_box\">";

		// end_tag 정의
		immutable string end_tag = "<div align=\"center\">\n<a href=";
		string start_tag;

		// class="content"가 검색됬는가?
		if( this.HTML.indexOf(format1) )
		{
			start_tag = format1;
		}
		// class="ctt_box"가 검색됬는가?
		else if( this.HTML.indexOf(format2))
		{
			start_tag = format2;
		}
		else // 이것도 저것도 검색이 안되는 경우 None.
		{
			debug{
				log("stripBody(fn)_thisHTML(str).txt", this.HTML);
			}
			return "None";
		}

		uint x = this.HTML.indexOf(start_tag) + start_tag.length;
		uint y = this.HTML[x..this.HTML.length].indexOf( end_tag );
		try{
			return this.HTML[x..x+y];
		}
		catch( core.exception.RangeError e )
		{
			debug
			{ log("stripBody(fn)_thisHTML(str)~RangeError.txt", this.HTML); }
		}
		return "None";
	}



	//
	// @ URL을 <a href~ 스타일로 재작성
	//
	string stripHref(){
		// 실제 콘텐츠 부분만 따옴
		string temp = stripBody();
		debug{ log( "stripHref(fn)_temp(str)1.txt", temp ); } 
		string stripHref;
		
		// <a~부분부터 개행으로 분리하고 필요없는 닫는 태그 지움( array[0]을 array[1]로 ... )
		string[] replace_list = [
			// 개행으로 보기 쉽게
			"><a",																">\n<a ",

			// 주요 삭제 태그들
			" *&nbsp; *",														"",
			" *amp; *",															"",
			" *</*span[!#A-z0-9=\"-:;,돋움굴림 \\.\\(\\)]*> *",					"", // span
			" *</*font[!#A-z0-9=\"-:;,돋움굴림 \\.\\(\\)]*> *",					"", // font
			" *</*p[!#A-z0-9=\"-:;,돋움굴림 \\.\\(\\)]*> *",						"", // p
			" *</*[div]{1,3}[!#A-z0-9=\"-:;,돋움굴림 \\.\\(\\)]*> *",			"", // div, i

			// 앵커에 붙은 스타일 삭제
			" *target=\"_[\\w]+\" *",											"",
			" *style=\"[!#A-z0-9=\"-:;,돋움굴림 \\.\\(\\)]+\"",					"",

			// 마무리
			"</[^a][spanfontdiv]*>",											"",
			" *<[fontspa]+ [stycolrface =\"#\\d\\w,:;\\.\\-\\(\\)]+> *",		"",
			"><a ",																">\n<a ",
			"</a><a",															"</a>\n<a",
			"ahref",															"a href"
		];

		// 태그 정리를 위한 치환
		for( int i; i <= replace_list.length-1; i+=2 )
		{
			temp = replaceAll( temp,
				regex( replace_list[i] ), replace_list[i+1]
			);

			// 단계별 디버그 출력
			debug{
				log("stripHref(fn)_temp(str)~ParsingStep"~to!string(i)~".txt", temp);
			}
		}

		// 치환 후에 결과 한번더 디버그 출력
		debug{ log( "stripHref(fn)_temp(str)2.txt", temp ); }

		// 입력 준비
		string[] split_result = split(temp, regex("\n") );

		foreach( line; split_result)
		{
			// href 따로 innerText 따로 추출하기
			string href, innerText;

			// 먼저 href
			auto obj = match( line, regex( this.CHAPTER_MATCHING_PATTHEN) );
			if( !obj.empty() )
			{
				href = obj.front.hit();
				debug { log( "stripHref(fn)_href(str).txt", href ); }

				/*
				auto obj2 = matchAll( line, regex("\">(.+)</a>") );
				foreach( e; obj2 ){
					innerText = e[1];
					// ">만화 <font~~> 3권<a href=" 같이 태그가 덜 지워진 경우 안에서 또 지우는 작업 시작
					if( innerText.indexOf("<") != -1 )
					{
						// span, font 태그에 대해서 한번에 지우는 패턴!
						innerText = replaceAll( innerText, regex(" *<[fontspa]+ [stycolrface =\"#\\d\\w,:;\\.\\-\\(\\)]+> *"), "" );
					}
				}
				debug{ log( "stripHref(fn)_stripHref.txt",  href~"  /  "~innerText ); }
				stripHref ~= "<a "~href~"\">"~innerText~"</a>\n";*/

				stripHref ~= href~"\n";
			}
			
		}
		debug{ log( "stripHref(fn)_stripHref(str).txt", stripHref ); }
		return stripHref;
	} 

	//
	// @ 커버이미지 URL 가져오기
	//
	string getCoverImage(){
		string html_fix = stripBody();
		string[] regex_patthens = [
			r"http:\/\/marumaru.in\/imgr\/[\S]+\.[jpneg]{3,4}",
			r"http:\/\/marumaru.in\/files\/[\d]+\/[\d]+\/[\d]+\/[\S]+\.[jpneg]{3,4}",
			r"http:\/\/marumaru.in\/[quickmager]{4,10}\/[\S]+\.[jpneg]{3,4}",
			r"http[s]*:\/\/[\d].bp.blogspot.com\/[\S]+\/[\S]+\/[\S]+\/[\S]+\/[\S]+\/[\S]+\.[jpneg]{3,4}",
			r"http[s]*:\/\/imagizer\.imageshack.us\/[\S]+\/[\S]+\/[\d]+\/[\S]+\.[jpneg]{3,4}"
		];
		
		// 패턴매칭 시작
		foreach( patthen; regex_patthens ) {

			// 일치하는 단 한개만 가져오기!
			auto result = match( html_fix, patthen );

			// 매치하는 게 있다면 https를 http로 바꾼 후 리턴.
			if( !result.empty() ){
				return replace( result.front.hit(), "https", "http");
			}
		}
		// **보류**
		// 이거 예외 처리 하긴 해야 됨...
		return "None";
	}



	//
	// @ 만화제목 얻기
	//
	string getTitle(){
		auto result = match( this.HTML, regex(r"<h1>(.+)<\/h1>") );
		string temp;
		foreach( e; result ) { temp = e[1]; }

		// <h1>~</h1> 태그 안에 또다른 태그가 존재한다면,
		if( temp.indexOf("<") != -1 || temp.indexOf(">") != -1 )
		{
			temp = replaceAll( temp, regex(" *</*[fontspa]+ *[stycolrface =\"#\\d\\w,:;\\.\\-\\(\\)]*> *"), "" );
		}
		return temp;
	}

	//
	// @ ~화:링크 얻기( 다형식 연관 배열 스타일로)
	//
	string[string][] getList(){
		string[string][] result;
		string temp = stripHref();

		debug{ string forlog = (temp~"\n\n\n\n\n"); }

		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, this.CHAPTER_MATCHING_PATTHEN);
			foreach( e; regex_result )
			{
				// key에 앵커(html:a) 태그가 있는 경우 제거하자 => 마루마루 페이지가 워낙 엉망이라서...
				// ex) 블리치:84968
				result~= [ e[2]:e[1] ];
				debug{ forlog ~=  (e[2]~":"~e[1]~"\n"); }
			}
		}

		debug{
			log("getList(fn)_forlog.txt", forlog);
		}
		result.length -= result.uniq().copy(result).length;
		return result;
	}

	//
	// @ ~화:링크 얻기(연관배열 스타일로)
	//
	string[string] getListByArray(){
		string[string] result;
		string temp = stripHref();

		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, this.CHAPTER_MATCHING_PATTHEN);
			foreach( e; regex_result )
			{
				string key, value;
				key = e[2]; value = e[1];
				result[key] = value;
			}
		}
		return result;
	}

	//
	// @ 만화이미지 얻어오기
	//
	string[] getImageUrls( string chapter_name )
	{
		string[] result = [];
		string[string][] list = null;
		
		list = getList();
		string[] regex_patthens = [
			"src=\"(http://[wblog\\.]*[sheyun]{3,4}comics.com/[wpm]{1,2}-content/upload[s]*/[\\d/]*[\\S]+\\.[JjPpEeNnGg]{3,4}[\\?\\d]*)\"",
			"src=\"(http://i.imgur.com/[\\S]+\\.[JjPpEeNnGg]{3,4})[%\\d]*\"",
			"src=\"(http://[wblog\\.]*[sheyun]{3,4}comics.com/[wpm]{1,2}-content/upload[s]*/[\\d/]*[\\S]+\\.[JjPpEeNnGg]{3,4}[\\?\\d]*)",
			"src=\"(http[s]*://[\\d]+\\.bp\\.blogspot\\.com/[\\S/-]*/[\\S]+\\.[JjPpEeNnGg]{3,4})\"",
			"src=\"/(storage/gallery/[\\w\\d_-]+/[가-힣 \\.\\w\\d_-]+\\.[JjPpEeNnGg]{3,4})"
		];

		foreach( element; list )
		{
			// 입력 받은 챕터와 리스트의 챕터가 같으면 다운받음. else없음.
			if( element.keys[0] == chapter_name )
			{
				// phantomjs로 js가포함된 웹페이지 html 얻어오기
				auto ghost = new Ghost( element[chapter_name] );
				string html = ghost.Grab();
				
				debug { log( "getImageUrl(fn)_html(str).txt", html ); }

				// 이미지 파일의 패턴 매칭-인장검출-다운로드받을리스트추가
				foreach( patthen; regex_patthens )
				{
					// url들.
					auto match_result = matchAll( html, regex(patthen) );
					if( !(match_result.empty())  )
					{
						// regex에 검색된 이미지 파일 하나하나씩 인장인지 확인하고 아닐 경우만 다운리스트에 추가
						foreach( temp; match_result )
						{
							// src="url", url 에서 url만 따온다 -> src= 부분 빼고 ... 
							string url = temp[1];

							// 이름이 혹시 (dummy.jpg?1234) 형식이라면 뒤에 ?~ 부분 삭제
							if( url.indexOf("?") != -1 ) { url = replaceAll( url, regex("\\?[\\d]+"), ""); }
							
							// 만약 (n).dp.blogspot.com에서 https라면 http로 변경
							url = replaceAll( url, regex("https://[\\d]+.bp.blogspot.com"), "http://3.bp.blogspot.com");

							// wasabisyrup 도메인 추가
							url = url.replace("storage/gallery","http://wasabisyrup.com/storage/gallery" );
							result ~= url;
						}
					}
				}
				// Exit - 만약 생성된 리스트가 비어있다면 Throw 함.
				if( result.length == 0 ) {
					string temp;
					foreach( e; regex_patthens) {
						temp~=(e~"\n");
					}
					debug{ log("used_patthens.txt", temp~"\n\nelement[key]: \n\nHTML:\n"~html); }
					throw new Error("Coudn't create a url list(만화의 목록을 가져올 수 없습니다.");
				}

				// 리스트에서 중복항목을 제거	
				result = ezUniq(result);

				// 리스트에서 마루마루 관련 인장 제거
				result = ezFilter(result, "우마루세로");
				result = ezFilter(result, "oeCAmOD");
			}
		}
		// 검색된 만화 URL 배열을 텍스트 로그 출력
		debug{
			logArray("getImageUrls(fn)_result(str[]).txt", result);
		}
		// 중복제거
		return ezUniq(result);
	}

	//
	// @ 다운로드 실행
	//
	void download( string chapter_name, string path=".", bool fix_name=true, bool cre_zip=false )
	{
		string[] member_path_list;
		string[] file_url_list = getImageUrls( chapter_name );
		if( file_url_list.length != 0 )
		{
			uint counter_num = 0; // 파일 이름 앞에 숫자(000N) 넣기 위한 변수 선언
			string counter_str = "";

			// 입력받은 url배열에서 요소 하나씩 꺼내기
			foreach( file_url; file_url_list )
			{
				// url상에서 파일이름만 추출
				import std.array:split;
				string file_name = file_url.split("/")[ file_url.split("/").length-1 ];
				
				// 추출된 파일이름 검증 & 검증되지 않으면 작업하지 않음.
				auto file_name_verify_match = match( file_url, regex("[\\S]+\\.[JjPpEeNnGg]{3,4}") );
				if( !file_name_verify_match.empty() )
				{
					// 원하는 경우에만 파일 앞에 0001~0009_로 서식변경
					if(fix_name)
					{
						import std.format;
						auto wf = std.array.appender!string();
						formattedWrite(wf, "%.4d",counter_num);
						counter_str = wf.data;
						counter_num+=1;
					}
							
					//
					// --------------- 다운로드 프로세싱 ---------------
					//
					string local_path = path~"/";
					file_name = replace(file_name, "/", "");

					// curl 다운로드 (
					//					호스팅된 이미지,
					//					./0001_dummy.jpg
					//				);

					string local_file_name = local_path~counter_str~"_"~file_name;

					std.net.curl.download(
						encode(file_url),
						local_file_name
					);
					debug{
						writeln("다운로드(download): "~ file_url~" To "~local_file_name);
					}

					// 압축해야할 리스트에 해당 파일 추가
					member_path_list ~= local_file_name;

					// 데이터 검증(~10kb이하면서 ?(n) 스타일의 URL이미지는 덧씌우기 작업을 한다)
					const ushort byte_verify = 10000;
					if( getSize( local_file_name ) <= byte_verify )
					{
						// '? + 랜덤 5자리' 생성
						import std.random:randomSample;
						string tail = "?";
						foreach (e; randomSample([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ], 5)) { tail ~= std.conv.to!string(e); }

						// 다운로드 재실행
						// http://www~ 주소 앞부분에 http:// 지워보기
						std.net.curl.download( encode(file_url~tail), local_file_name );
						debug{
							writeln("데이터검증대상(byte_verify): "~local_file_name);
							writeln("다운로드재실행(download): "~file_url~tail~" To "~local_file_name);
						}
					}

					//
					// --------------- 압축파일 생성 여부 ---------------
					//
					if( cre_zip )
					{
						// 풀 파일 경로에서(/urs/bin/) bin만 구해옴
						auto local_path_array = split(path, "/");
						string arch_file_name = local_path_array[ local_path_array.length-1 ]~".zip";
						
						// 압축파일 생성 시작
						import std.zip: ArchiveMember, ZipArchive,CompressionMethod;
						auto arch_obj = new ZipArchive();

						foreach( member_path; member_path_list )
						{

							// 다운로드 받은 이미지 파일이 존재할 때만 쓰기 시작
							if( exists(member_path) )
							{
								debug{
									writeln("압축(ZIP): "~member_path~", 존재함! 압축멤버에 추가시작");
								}
								// 이미지 파일 읽기
								auto member_file = File(member_path, "r+");
								// 이미지 파일 크기만큼 byte 배열 생성
								auto member_bytes = new ubyte[ cast(uint)getSize(member_path) ];
								// byte배열에 읽은 데이터를 담는다
								member_file.rawRead(member_bytes);
								// ZIP 멤버 1)생성 + 2)데이터 담고 + 3)압축률 지정
								ArchiveMember member_obj = new ArchiveMember();
								member_obj.name = split(member_path,"/")[ split(member_path,"/").length-1 ];
								member_obj.expandedData(member_bytes);
								member_obj.compressionMethod(CompressionMethod.deflate);
								
								// 압축파일에 멤버 추가
								arch_obj.addMember( member_obj );
							}
						}
						// 최종 압축
						void[] compressed_data = arch_obj.build();
						std.file.write( path~"/"~arch_file_name, compressed_data);
						debug{
							writeln("압축(ZIP): "~path~"/"~arch_file_name~", 생성완료!");
						}
					}
				}
				// 추출된 파일이름 검증에 실패한다면,
				else
					{ throw new Error("Coudn't verify url format(URL 상에서의 파일이름 검증에 실패했습니다)."); }
			}
		}
		else
			{ throw new Error("Coudn't get image urls(이미지URL을 얻어오는데 실패했습니다).\nAddress(참조):"~this.ID); }
	}
}

//--------------------------------------------------------------------------------
//
// - [ 마루마루 만화클래스;끝 ] -
//
//--------------------------------------------------------------------------------