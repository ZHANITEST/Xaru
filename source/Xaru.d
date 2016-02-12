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





//
// 로그 작성(기본값:true)
//
const bool LOG_ENABLE = false;





// 카테고리 리스트
string[] CategoryList = ["단편", "주간", "격주", "월간", "격월/비정기", "단행본", "완결", "붕탁", "와이!", "오토코노코+엔솔로지", "여장소년+엔솔로지", "오토코노코타임", "붕탁+완결"];





//
// 디렉토리 만들기
//
void makedir( string path ){
		if( !exists(path) ){ mkdir(path); }
}





//
// 유니크
//
string[] ezUniq(string[] ori)
{
	string[] fix; foreach( e; ori){ import std.algorithm.searching:canFind; if( !canFind(fix, e) ){ fix~=e; } } return fix;
}





//
// PhantomJS DIRTY Handler
//
class Ghost{
	public string Url;
	public string FileName;

	this( string url )
	{
		this.Url = url;
		this.FileName = "phantomjs.exe";
	}

	bool hadTomb(){
		if( std.file.exists(this.FileName) )
		{
			return true;
		}
		else
		{ return false; }
	}

	string Grab(){
		File f = File("grab.js", "w");
		f.write("var f = require('fs'); var webPage = require('webpage');var page = webPage.create(); page.open('"~this.Url~"', function(status) {setTimeout(function(){ console.log(page.content);phantom.exit();}, 30000);});");
		f.close();

		
		auto pid = pipeProcess(["phantomjs", "grab.js"],Redirect.all,null,Config.suppressConsole);
		//auto pid = pipeProcess(args=["phantomjs", "grab.js"]);
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
	//auto http = HTTP(url);
	//http.setUserAgent( "Mozilla/5.0 (compatible;  MSIE 7.01; Windows NT 5.0)" );
	string html;
	try
		{ html = cast(string)get(url); } //{ html = cast(string)get(url, http); }
	catch(CurlException e)
		{ return e.msg; exit(0); }
	return html;
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
		// 실제 콘텐츠 부분만 따옴
		string temp = stripBody();
		fetch( "stripBody.txt", temp );
		string stripHref;
		
		// <a~부분부터 개행으로 분리하고 필요없는 닫는 태그 지움
		string[] target_lsit = [
			"><a ",
			"</[^a][font]*>",
			"</[^a][span]*>",
			" *&nbsp; *",
			"><a "
		];
		string[] replace_list = [
			">\n<a ",
			"", "", "",
			">\n<a "
		];

		for( int i; i <= target_lsit.length-1; i++ )
		{
			temp = replaceAll( temp, regex(target_lsit[i]), replace_list[i]);
		}
		string[] split_result = split(temp, regex("\n") );

		foreach( line; split_result)
		{
			string href, innerText;
			auto obj = match( line, regex("href=\"[https]*://[w]*.shencomics.com/archives/[\\d]+") );
			if( !obj.empty() )
			{
				href = obj.front.hit(); fetch( "stripHref_href.txt", href );
				auto obj2 = matchAll( line, regex("\">([^<>].+)</a>") );
				foreach( e; obj2 ){
					innerText = e[1];
					// ">만화 <font~~> 3권<a href=" 같이 태그가 덜 지워진 경우 안에서 또 지우는 작업 시작
					if( innerText.indexOf("<") != -1 )
					{
						// span, font 태그에 대해서 한번에 지우는 패턴!
						innerText = replaceAll( innerText, regex("<[fontspa]+ [stycolrface =\"#\\d\\w,:;\\.\\-\\(\\)]+>"), "" );
					}
				}
				fetch( "stripHref_innerText.txt", innerText );
				stripHref ~= "<a "~href~"\">"~innerText~"</a>\n";
			}
			
		}
		fetch( "stripHref_stripHref.txt", stripHref );
		return stripHref;
	}



	//
	// ~화:링크 얻기( 다형식 연관 배열 스타일로)
	//
	string[string][] getList(){
		string[string][] result;
		string temp = stripHref();
		foreach( line; split(temp, regex("\n")) )
		{
			auto regex_result = matchAll(line, "<a href=\"(http://[w\\.]*shencomics.com/archives/[\\d]+)\">(.+)</a>");
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
			auto regex_result = matchAll(line, "<a href=\"(http://[w\\.]*shencomics.com/archives/[\\d]+)\">(.+)</a>");
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
	// 다운로드 실행
	//
	void download( string key, string path=".", bool fix_name=true, bool cre_zip=false  ){
		string[string][] list = getList();
		foreach( element; list )
		{
			if( element.keys[0] == key )
			{
				auto ghost = new Ghost( element[key] );
				string html = ghost.Grab();
				fetch( "body_ghost.txt", html );

				//string[] regex_patthens = [
				//	"src=\"(http://[w\\.]*shencomics.com/wp-content/upload[s]*/[\\d]+/[\\d]+/([\\S]+\\.[jpeng]{3,4})[\\?\\d]*)\"",
				//	"src=\"(http://[\\d]+.bp.blogspot.com/[\\S]+/([\\S]+\\.[jpneg]{3,4}))\"",
				//	"href=\"(http://[\\d]+.bp.blogspot.com/[\\S]+/([\\S]+\\.[jpneg]{3,4}))\"", // href와 src 분리
				//	"src=\"(http://i.imgur.com/([\\S]+\\.[jpneg]{3,4}))[%\\d]*\"",
				//	"src=\"(http:\\/\\/[w\\.]*shencomics.com\\/wp-content\\/upload[s]*\\/[\\d/]+\\/([\\S]+\\.[jpeng]{3,4})[\?\\d]*)"
				//];

				string[] regex_patthens = [
					"src=\"(http://[w\\.]*shencomics.com/wp-content/upload[s]*/[\\d]+/[\\d]+/[\\S]+\\.[jpeng]{3,4}[\\?\\d]*)\"",
					"src=\"(http://[\\d]+.bp.blogspot.com/[\\S]+/[\\S]+\\.[jpneg]{3,4})\"",
					"href=\"(http[s]*://[\\d]+.bp.blogspot.com/[\\S]+/[\\S]+\\.[jpneg]{3,4})\"", // href와 src 분리
					"src=\"(http://i.imgur.com/[\\S]+\\.[jpneg]{3,4})[%\\d]*\"",
					"src=\"(http://[w\\.]*shencomics.com/wp-content/upload[s]*/[\\d/]+/[\\S]+\\.[jpeng]{3,4}[\?\\d]*)"
				];

				uint counter = 0;
				foreach( patthen; regex_patthens )
				{
					auto match_result = matchAll( html, regex(patthen) );
					if( !(match_result.empty())  )
					{
						//string[][] result_array;
						string[] member_path_list;
						string[] file_url_list = [];

						// 다운로드 받을 url 리스트 생성(중복과 인장 제거)
						foreach( temp; match_result )
						{
							
							import std.algorithm.searching:canFind;
							string url = temp[1];
							
							// 우마루 인장은 리스트에 넣지 않는다
							if( !canFind( url, "우마루세로") && !canFind( url, "oeCAmOD.jpg") )
							{
								// (n).dp.blogspot.com의 https를 http로 우회한다. 에효...
								url = replaceAll( url, regex("https://[\\d]+.bp.blogspot.com"), "http://4.bp.blogspot.com");
								
								// 최종적으로 리스트에 추가
								file_url_list ~= url;
							}
						}

						// 중복제거
						file_url_list = ezUniq(file_url_list);

						// 다운로드 작업 시작 전에 폴더를 경건하게 비우고 시작한다
						//import std.file:dirEntries, SpanMode, remove;
						//foreach( e; dirEntries(path, "*.*", SpanMode.shallow) ) { remove(e); }

						// 다운로드 작업 시작
						uint counter_num = 0;
						foreach( file_url; file_url_list )
						{
							// 파일이름이 혹시 (dummy.jpg?1234) 형식이라면 뒤에 ?부터 지운다.
							if( file_url.indexOf("?") != -1 )
								{ file_url = replaceAll( file_url, regex("\\?[\\d]+"), ""); }

							// url상에서 파일이름만 추출
							import std.array:split;
							string file_name = file_url.split("/")[ file_url.split("/").length-1 ];

							/*
							string file_name = file_url.split("/")[ file_url.split("/").length-1 ];
							
							// 파일이름이 혹시 (dummy.jpg?1234) 형식이라면 뒤에 ?부터 지운다
							if( file_name.indexOf("?") != -1 ){
								file_name = replaceAll( file_name, regex("\\?[\\d]+"), "");
							}*/


							auto file_name_verfiy_match = match( file_url, regex("[\\S]+\\.[jpneg]{3,4}") );
							if( !file_name_verfiy_match.empty() )
							{
								// [체크]-1~9는 01~09로 서식변경
								string counter_str;
								
								if(fix_name)
								{
									import std.format;
									auto wf = std.array.appender!string();
									formattedWrite(wf, "%.2d",counter_num);
									counter_str = wf.data; counter_num+=1;
								}
								else
									{ counter_str = to!string(counter_num); }
								

								string local_path = path~"/";
								file_name = replace(file_name, "/", "");
								fetch("download_link.txt", file_url~":"~local_path~counter_str~"_"~file_name );
								std.net.curl.download( file_url, local_path~counter_str~"_"~file_name ); counter+=1;

								// 압축 리스트 작성
								member_path_list ~= local_path~counter_str~"_"~file_name;		
							}

						}



						// [체크]-ZIP압축 여부
						if( cre_zip )
						{
							// 풀 파일 경로에서(/urs/bin/) bin만 구해옴
							import std.array:split;
							auto local_path_array = split(path, "/");
							string arch_file_name = local_path_array[ local_path_array.length-1 ]~".zip";
							
							//member_path_list=[];
							//foreach( e;  dirEntries(path, "*.{pn,jpe,jp}g", SpanMode.shallow, false) ){ member_path_list~=e; }

							// 압축파일 생성 시작
							import std.zip: ArchiveMember, ZipArchive,CompressionMethod;
							auto arch_obj = new ZipArchive();

							foreach( member_path; member_path_list )
							{
								uint temp_uint = 0;
								while( member_path_list.length != temp_uint )
								{
									// 다운로드 받은 이미지 파일이 존재할 때만 쓰기 시작
									if( exists(member_path) )
									{
										temp_uint+=1;
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
							}

							// 최종 압축
							void[] compressed_data = arch_obj.build();
							std.file.write( path~"/"~arch_file_name, compressed_data);
						}
					}
					else
					{ fetch("matching_fail.txt", html); }
				}
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