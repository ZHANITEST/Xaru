module Xaru;
import std.net.curl;
import std.regex;
import std.stdio;
import std.conv;
import std.algorithm;
import std.string:indexOf;
import std.file;
import std.process;

string[] CategoryList = ["단편", "주간", "격주", "월간", "격월/비정기", "단행본", "완결", "붕탁", "와이!", "오토코노코+엔솔로지", "여장소년+엔솔로지", "오토코노코타임", "붕탁+완결"];

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
// 만화 카테고리 데이터
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





string GET( string url ){
	auto http = HTTP( url ); http.setUserAgent( "Mozilla/5.0 (compatible;  MSIE 7.01; Windows NT 5.0)" );
	return( cast(string)get(url, http) );
}





class MaruMaru{
	private string HTML;
	private string BASE_URl;
	void navigate( string url ){
		this.HTML = GET(url);
	}



	// 검색
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

	string[string] getCartoonList( Category cat_ ){
		auto cat = cat_;
		string id		= cat[1];
		string category = cat[0];
		string base_url = "www.marumaru.in/?c=1/"~id;
		string[string] CartoonList;	// 인덱스 리스트
		uint page_count;			// 페이지 수
		
		// 이 카테고리의 페이지는 얼마나 되느뇨?
		string html = GET( base_url );
		auto match_result = matchAll( html, regex(r">([\d]+)</[span]{1,4}>") ); string[] temp;
		foreach( element; match_result ){
			temp ~= element[1];
		}
		sort( temp ); page_count = to!uint( temp[temp.length-1] );
		
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

	string[string] getIndexlist( Category cat_ )
	{
		auto cat = cat_;
		string id		= cat[1];
		string category = cat[0];
		//string base_url = "www.marumaru.in/?c=1/"~id~"&cat="~category~"&p=1";
		string base_url = "www.marumaru.in/?c=1/"~id;
		string[string] CartoonList;	// 인덱스 리스트
		ubyte page_count;			// 페이지 수
		
		// 이 카테고리의 페이지는 얼마나 되느뇨?
		string html = GET( base_url );
		auto pageCount_Result = matchAll( html, regex(r">([\d]+)</[span]{1,4}>") ); string[] temp;
		foreach( element; pageCount_Result ){ temp ~= element[1]; }
		sort( temp ); page_count = to!ubyte( temp[ temp.length-1 ] );
		
		// 페이지 별로 파싱 (1, 2, 3 페이지...)
		foreach( page; temp ){
			html = cast(string)get( base_url~"&cat="~category~"&p="~page );
			auto urlNtitle = matchAll( html, regex( r"uid=([\d]+).><span class=.cat.>[\S ]+<\/span>([\d\S ]+)<\/a>"));
			// 1차 패턴: <a href\=\"([\S].+)\"><span class=\"cat\">\[\S{1,5}\]<\/span>([0-9 \S]+)<\/a>
			// 2차 패턴: uid=([\d]+).><span class=.cat.>\[\S{1,5}\]<\/span>([0-9 \S]+)<\/a>
			// 3차 패턴: uid=([\d]+).><span class=.cat.>[\S ]+<\/span>([\d\S ]+)<\/a>
			foreach( element; urlNtitle ){
				CartoonList[ element[2] ] ~= element[1] ;
			}
		}
		return CartoonList;
	}
}

class Cartoon{
	private string ID;
	private string HTML;

	this( string id ){
		this.ID = id;
		this.HTML = GET( "http://marumaru.in/b/manga/"~this.ID );
	}



	// vContent 내용만 가져오기.
	private string stripBody(){
		uint x = this.HTML.indexOf( "<div id=\"vContent\" class=\"content\">" ) + "<div id=\"vContent\" class=\"content\">".length;
		uint y = this.HTML.indexOf( "<div align=\"center\">\n<center>" );
		return( this.HTML[x..y] );
	}



	bool check(){
		// reload it.
		this.HTML = GET( "http://marumaru.in/b/manga/"~this.ID );
		return false;
	}



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
		return "can't found";
	}



	// 만화제목 얻기
	string getTitle(){
		auto result = match( this.HTML, regex(r"<h1>(.+)<\/h1>") ); string a;
		foreach( temp; result )
			{ a = temp[1]; }
		return a;
	}



	string stripHref(){
		string temp = replaceAll( stripBody(), regex("</div>"), "");
		temp = replaceAll( temp, regex("</span>"), "");
		temp = replaceAll( temp, regex("</font>"), "");

		string[] styles = [
			" *line-height: [\\d]+\\.*[\\d]*[ptx;\"]*",
			" *color: rgb\\([\\d]+, [\\d]+, [\\d]+\\)[ ;]*",
			" *font-family: [\\S]+[; ,]*[\\D]*; *",
			" *font-size: *[\\d]*[\\.\\dptxem]*[; ]*",
			" *text-decoration: [\\S]+; *",
			" *text-align: [\\S]+; *",

			" *border: [\\dptx]+; *",
			" *margin: [\\dptx]+; *",
			" *padding: [\\dptx]+; *",

			"background-\"",
			"border-bottom-\"",
			" *border-bottom-width: [\\d]+[\\.\\dpxt]*; *",
			" *border-bottom-style: [\\S]+; *",

			" *vertical-align: [\\S]+; *",
			" *margin-bottom: *[\\d]*[\\.\\dptxem]*[; ]*",

			" *box-sizing: [\\S]+;\"* *",

			" *style=\"\"*"
		];

		string[] tags = [
			" *align=\"[\\S]+\" *",
			" *target=\"[\\S]+\" *",
			" *color=\"[#\\d]+\" *",
			" *size=\"[\\d]+[\\.\\dptx]*\" *",
			" *class=\"[\\S]+\"",
			" *list-style-type: [\\S]+; *",
			" *face=\"[돋움굴림나눔맑은고딕체a-zA-Z, -]+\" *",
			" *font-[\\S]+: [\\S\\d]+; *",
			" *outline: [\\d]+[pxt]*; *"
		];

		string[] singles = [
			" *&nbsp[ ;]*",
			" *</*div\"*> *",
			" *</*br>",
			" *</*div\"*>",
			" *</*span\"* *>*",
			" *</*font\"* *>*",
			" *</*p> *",
			" *</*li\"*> *",
			" *</*ol> *",
			" *</*h1> *"
		];
	
		foreach( e; styles ) { temp = replaceAll(temp,regex(e),""); }
		foreach( e; tags ) { temp = replaceAll(temp,regex(e),""); }
		foreach( e; singles ){ temp = replaceAll(temp,regex(e),""); }

		// 교정 작업.
		// -- </a>href="url">chap</a>
		temp = replaceAll(temp,regex("</a>href"),"</a>\n<ahref");
		// -- </a>large;>
		temp = replaceAll(temp,regex("a>[\\S]+;>"),"a>");
		// -- <a  href
		temp = replaceAll(temp,regex("<a [\\s]+href"),"<a href");


		// 마지막으로 보기 좋으라고
		temp = replaceAll(temp,regex("<ahref"),"<a href");
		temp = replaceAll(temp,regex("><a"),">\n<a");


		return temp;
	}



	// ~화:링크 얻기
	string[string][] getList(){
		string[string][] result;
		string temp = stripHref();
		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, "<a href=\"(http://[www\\.]*mangaumaru.com/archives/[\\d]+)\">(.+)</a>");
			foreach( e; regex_result )
				{ result~= [ e[2]:e[1] ]; }
		}
		return result;
	}
	


	private void fileDownload( string html, string path )
	{
		string[] regex_patthens = [
			r"http:\/\/www.mangaumaru.com\/wp-content\/uploads\/[\d]{4}\/[\d]{2}\/([\S]+\.[jpneg]{3,4})",
			r"http:\/\/www.mangaumaru.com\/wp-content\/uploads\/[\d]{4}\/[\d]{2}\/([\S]+\.[jpneg]{3,4})\?[\S]+"
		];
		
		foreach( patthen; regex_patthens )
		{
			auto match_result = matchAll( html, regex(patthen) );
			if( !(match_result.empty()) ){
				foreach( element; match_result )
				{
					std.net.curl.download( element[0], element[1] );
				}
			}
		}
	}



	void download( string key, string path="./" ){
		string[string][] list = getList();
		foreach( element; list )
		{
			if( element.keys[0] == key )
			{
				//std.net.curl.download(element[key]);
				auto ghost = new Ghost( element[key] );
				string html = ghost.Grab();
				fileDownload( html, path );
			}
		}
	}
}
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