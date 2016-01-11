/*

	Xaru.d
	License: LGPL v2

	By ZHANITEST
		* zhanitest.egloos.com
		* steamcommunity.com/id/zhanitest

*/
module Xaru;
import std.net.curl;
import std.regex;
import std.stdio;
import std.conv;
import std.algorithm;
import std.string:indexOf;
import std.file;
import std.process;
import std.array:replace;
import arsd.dom; // dom parser





// 카테고리 리스트
string[] CategoryList = ["단편", "주간", "격주", "월간", "격월/비정기", "단행본", "완결", "붕탁", "와이!", "오토코노코+엔솔로지", "여장소년+엔솔로지", "오토코노코타임", "붕탁+완결"];





//
// 디렉토리 만들기
//
void makedir( string path ){
		if( !exists(path) ){ mkdir(path); }
}





//
// 로그 작성(기본값:true)
//
const bool LOG_ENABLE = true;




//
// PhantomJS DIRTY Handler
//
class Ghost{
	public string Url;
	public string FileName;

	this( string url )
	{
		this.Url = url;
	}

	bool hadTomb(){
		if( std.file.exists("phantomjs.exe") )
		{
			return true;
		}
		else
			{ return false; }
	}

	string Grab(){
		File f = File("grab.js", "w");
		f.write("var f = require('fs'); var webPage = require('webpage');var page = webPage.create(); page.open('"~this.Url~"', function(status) {setTimeout(function(){ console.log(page.content);phantom.exit();}, 10000);});");
		f.close();

		auto pid = pipeProcess(["phantomjs", "grab.js"]);
		scope(exit) wait(pid.pid);

		string result = "";
		foreach(line; pid.stdout.byLine){
			result ~= line;
		}
		//std.file.remove("grab.js");
		return result;
	}
}





//
// Category Enum
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
// GET method by cURL
//
string GET( string url ){
	auto http = HTTP( url ); http.setUserAgent( "Mozilla/5.0 (compatible;  MSIE 7.01; Windows NT 5.0)" );
	return( cast(string)get(url, http) );
}





//
// spacial Character replace
//
string stripSpecialChars( string body_ ){
	string result = body_;
	string table[] = [ "/", ":", "*", "?", "<", ">", "|" ];
	foreach( e; table ){
		result = result.replace( e, "_" );
	}
	return result;
}





//
// MaruMaru Site parsing class
//
class MaruMaru{
	private string HTML;
	private string BASE_URl;
	void navigate( string url ){
		this.HTML = GET(url);
	}



	//
	// 검색
	//
	string[string][] search( string keyword ){
		string[string][] result;
		navigate("http://marumaru.in/?r=home&mod=search&keyword="~keyword~"&x=0&y=0");
		string patthen = "<a href=\"/b/manga/([\\d]+)\" class=\"subject\">\n<table>\n<tr>\n<td>\n<span class=\"[\\S]+\"><img src=\"http://[\\dmarumarubp\\.blogspot]+\\.[incom]+.[quimagckrfles]+/[\\S]+\" width=\"[\\d]+\" height=\"[\\d]+\" alt=\"[\\S]*\"/></span>\n</td>\n<td>\n<div class=\"sbjbox\">\n<b>([\\S \\[\\]]+)</b>";
		auto match_result = matchAll( this.HTML, regex(patthen) );
		foreach( element; match_result ){
			result ~= [ element[2]:element[1] ];
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





//
// MaruMaru Cartoon parsing class
//
class Cartoon{
	private string ID;
	private string HTML;



	//
	// 생성자
	//
	this( string id ){
		this.ID = id;
		this.HTML = GET( "http://marumaru.in/b/manga/"~this.ID );
		if( this.HTML.indexOf( "<div id=\"vContent\"" ) == -1 ){
			throw new Exception("Can't not open http://marumaru.in/b/manga/"~id);
		}
	}



	//
	// 본문만 따오기(vContent)
	//
	private string stripBody(){
		uint x = this.HTML.indexOf( "<div id=\"vContent\" class=\"content\">" ) + "<div id=\"vContent\" class=\"content\">".length;
		uint y = this.HTML.indexOf( "<div align=\"center\">\n<center>" );
		return( this.HTML[x..y] );
	}



	//
	// 파일 로그
	//
	private void fetch( string filename, string body_ ){
		if(LOG_ENABLE){
			auto f = new File( filename, "w"); f.write( body_ ); f.close();
		}
	}



	//
	// 커버이미지 URL 가져오기
	//
	string getCoverImage(){		
		string html_fix = stripBody();
		string[] regex_patthens = [
			r"http:\/\/marumaru.in\/files\/[\d]+\/[\d]+\/[\d]+\/[\S]+\.[jpneg]{3,4}",
			r"http:\/\/marumaru.in\/[quickmager]{4,10}\/[\S]+\.[jpneg]{3,4}",
			r"http:\/\/[\d].bp.blogspot.com\/[\S]+\/[\S]+\/[\S]+\/[\S]+\/[\S]+\/[\S]+\.[jpneg]{3,4}",
			r"https:\/\/imagizer\.imageshack.us\/[\S]+\/[\S]+\/[\d]+\/[\S]+\.[jpneg]{3,4}"
		];
		
		foreach( patthen; regex_patthens )
		{
			auto result = match( html_fix, patthen );
			if( !result.empty() ){
				return result.front.hit();
			}
		}
		return "";
	}



	//
	// 만화제목 얻기
	//
	string getTitle(){
		auto result = match( this.HTML, regex(r"<h1>(.+)<\/h1>") ); string a;
		foreach( temp; result ) { a = temp[1]; }
		return a;
	}



	//
	// <a href~ 스타일로 코드 새로 작성
	//
	string stripHref(){
		//auto document = new Document();
		string temp = stripBody();
		fetch( "stripBody.txt", temp );
		string body_;
		temp = replaceAll( temp, regex("><a "), ">\n<a ");
		temp = replaceAll( temp, regex("</[^a][font]*>"), "");
		temp = replaceAll( temp, regex("</[^a][span]*>"), "");
		temp = replaceAll( temp, regex(" *&nbsp; *"), "");
		temp = replaceAll( temp, regex("><a "), ">\n<a ");
		string[] split_result = split(temp, regex("\n") );
		foreach( line; split_result)
		{
			string href, innerText;
			auto obj = match( line, regex("href=\"[https]*://[w]*.mangaumaru.com/archives/[\\d]+") );
			if( !obj.empty() )
			{
				href = obj.front.hit();
				fetch( "href.txt", href );
				auto obj2 = matchAll( line, regex("\">([^<>].+)</a>") );
				foreach( e; obj2 ){ innerText = e[1]; }
				fetch( "href2.txt", innerText );
				body_ ~= "<a "~href~"\">"~innerText~"</a>\n";
			}
			
		}
		fetch( "body_.txt", body_ );
		return body_;
	}



	//
	// ~화:링크 얻기( 다형식 연관 배열 스타일로)
	//
	string[string][] getList(){
		string[string][] result;
		string temp = stripHref();
		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, "<a href=\"(http://[w\\.]*mangaumaru.com/archives/[\\d]+)\">(.+)</a>");
			foreach( e; regex_result )
				{ result~= [ e[2]:e[1] ]; }
		}
		result.length -= result.uniq().copy(result).length;
		return result;
	}


	//
	// ~화:링크 얻기(연관배열 스타일로)
	//
	string[string] getListByArray(){
		string[string] result;
		string temp = stripHref();
		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, "<a href=\"(http://[w\\.]*mangaumaru.com/archives/[\\d]+)\">(.+)</a>");
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
	// 디렉토리 만들기
	//
	/*private void makedir( string path ){
		string path_real = stripSpecialChars(path);
		if( !exists(path_real) ){ mkdir(path_real); }
	}*/



	//
	// 파일 다운로드
	//
	private void fileDownload( string html, string path, bool fix_a_filename )
	{
		string[] regex_patthens = [
			"src=\"(http://[w\\.]*mangaumaru.com/wp-content/upload[s]*/[\\d]+/[\\d]+/([\\S]+\\.[jpeng]{3,4})[\\?\\d]*)\"",
			"src=\"(http://[\\d]+.bp.blogspot.com/[\\S]+/([\\S]+\\.[jpneg]{3,4}))\"",
			"href=\"(http://[\\d]+.bp.blogspot.com/[\\S]+/([\\S]+\\.[jpneg]{3,4}))\"", // href와 src 분리
			"src=\"(http://i.imgur.com/([\\S]+\\.[jpneg]{3,4}))[%\\d]*\""
		];
		uint counter = 0;
		foreach( patthen; regex_patthens )
		{
			auto match_result = matchAll( html, regex(patthen) );
			if( !(match_result.empty())  )
			{
				//string[][] result_array;
				foreach( element; match_result ){
					string fileName = element[2];
					string urlName = element[1];
					string counter_str = "";

					// 우마루 로고 인장파일 제거
					auto r1 = match( fileName, regex("[\\d_]*oeCAmOD.jpg"));
					auto r2 = match( fileName, regex("[\\d_]*우마루세로[\\d]-[\\dx]+.jpg"));
					if( r1.empty && r2.empty ){
						
						// 1~9는 01~09로 서식변경
						if(fix_a_filename)
						{
							import std.format; auto wf = std.array.appender!string(); formattedWrite(wf, "%.2d",counter);
							counter_str = wf.data;
						}
						else { counter_str = to!string(counter); }
						
						path = path~"/";

						fetch("download_link.txt", urlName~":"~path~counter_str~"_"~fileName );
						std.net.curl.download( urlName, path~counter_str~"_"~fileName ); counter+=1;
					}
				}
			}
			else
			{ fetch("matching_fail.txt", html); }
		}
	}



	//
	// 다운로드 실행
	//
	void download( string key, bool fix_a_filename, string path=".",   ){
		string[string][] list = getList();
		foreach( element; list )
		{
			if( element.keys[0] == key )
			{
				auto ghost = new Ghost( element[key] );
				string html = ghost.Grab();
				fetch( "body_ghost.txt", html );
				fileDownload( html, path, fix_a_filename );
			}
		}
	}
}





//
// 문자열 형식을 카테고리(enum) 데이터로
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