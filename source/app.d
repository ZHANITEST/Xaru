import std.array;
import std.stdio;
import std.conv;
import std.format;
import std.string;
import std.parallelism;
import std.exception: enforce;
import core.sys.windows.windows: CP_UTF8, SetConsoleOutputCP;
static import uri = std.uri;
import requests;
import marumaru;
import mini;

const string ver = "0.3A";

int main(string[] args)
{
	// 빌어먹을 서구권 컴파일러의 한글깨짐 방지(UTF-8 설정)
	version(Windows){
		SetConsoleOutputCP(CP_UTF8).enforce;
	}
	
	// 빌드모드 명시
	string build_mode = "release";
	debug{ build_mode = "debug"; }

	writeln(" [ xaru.d ] v"~ver~"("~build_mode~") / Copyleft 2017 zhanitest(.egloos.com) / LGPL v2");
	makeDir("download");
	string cmd_id;

	// ID 입력 또는 입력변수로 받기
	if(args.length <= 1){
		write(">>> ");
		cmd_id = readln();
		cmd_id = cmd_id.replace("\n", "");
	}
	else if(args.length == 2)
		{ cmd_id = args[1]; }
	else if(args.length == 3 && args[1]=="-idx"){
		miniapp temp = new miniapp(args[2]);
		temp.download();
		return 0;
	}

	// 회차 얻기
	auto cp = new comicPage(cmd_id);
	comic co = cp.getLink();

	// 디스플레이
	writeln("--------------------------------------------------");
	uint index = 0;
	foreach(l; co.links){
		write("    [");
		write(index);
		write("] : ");
		writeln(l.title);
		index += 1;
	}
	writeln("--------------------------------------------------");
	write("[ 회차입력:Index1-Index2 / 모두선택:* ] >>> ");
	string cmd_selection = readln().replace("\n", "");

	// 다중선택(시작/끝 인덱스 값)
	uint start;

	// LDC2컴파일러 대응을 위해 ulong으로 처리
	ulong end;
	
	if( cmd_selection.indexOf("-")!= -1 ){
		// 입력 커맨드를 처리가능하게 편집
		string[] select = cmd_selection.split("-");
		start = to!uint(select[0]);
		end = to!uint(select[1])+1;
	}
	else if( cmd_selection == "*" ){
		start = 0;
		end = co.links.length;
	}
	else{
		writeln("옳바르지 않은 명령어 입니다...");
	}

	for(int i=start; i<end; i++){
		string[] web_url = co.getFileUrl(i);
		string chapter_name = co.links[i].title;

		string path = "./download/["
			~co.id~"] "~stripChar(co.title)~"/"~stripChar(chapter_name)~"/";
		
		writeln(path);
		makeDir(path);

		string[string] re_name;
		
		 //252870
		for(short count=0; count<web_url.length; count++){
			string f = web_url[count].split("/")[$-1];
			auto n = std.array.appender!string();
			formattedWrite(n, "%.4d", count);
			re_name[web_url[count]] = n.data~"_"~f;
		}
		
		writeln("다운로드 시작: "~chapter_name);
		foreach(e; parallel(web_url) ){

			debug{ writeln("chap url:"~co.links[i].url); } // refer헤더에 들어갈 값
			auto rq = Request();
			rq.sslSetCaCert("cacert.pem"); // 인증서 추가
			rq.addHeaders([ //  헤더추가
				"Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
				"Accept-Encoding":"gzip, deflate",
				"Accept-Language":"ko-KR,ko;q=0.8,en-US;q=0.5,en;q=0.3",
				"Connection":"keep-alive",
				"Host":"wasabisyrup.com",
				"Referer":co.links[i].url,
				"Upgrade-Insecure-Requests":"1",
				"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:61.0) Gecko/20100101 Firefox/61.0"
			]);

			auto ds = rq.get(uri.encode(e));
			// 파일 다운로드
			//File f = File(path~re_name[e], "wb");
			//f.rawWrite(ds.responseBody.data);
			//f.close();
			std.file.write(
				path~re_name[e],
				ds.responseBody.data
			);
		}
		writeln("다운로드 완료: "~chapter_name);
		writeln("______________________________________________________________________");
	}
	return 0;
}
