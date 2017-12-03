import std.array;
import std.stdio;
import std.conv;
import std.format;
import std.string;
import std.parallelism;
static import uri = std.uri;
import requests;
import marumaru;

version(Windows){
	extern(C) int setlocale(int, char*);
	static this(){
		core.stdc.wchar_.fwide(core.stdc.stdio.stdout, 1);
		setlocale(0, cast(char*)"korea");
	}
}


const string ver = "0.27A";

void main(string[] args)
{
	writeln(" [ xaru.d ] v"~ver~" / Copyleft 2017 zhanitest(.egloos.com) / LGPL v2");
	makeDir("download");
	string cmd_id;

	// ID 입력 또는 입력변수로 받기
	if(args.length <= 1){
		write(">>> ");
		cmd_id = readln();
		cmd_id = cmd_id.replace("\n", "");
	}
	else
		{ cmd_id = args[1]; }

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

	// 다중선택
	uint start, end;
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
			~co.id~"]"~stripChar(co.title)~"/"~stripChar(chapter_name)~"/";
		
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
			auto rq = Request();
			auto ds = rq.get(uri.encode(e));
			
			std.file.write(
				path~re_name[e],
				ds.responseBody.data
			);
		}
		writeln("다운로드 완료: "~chapter_name);
		writeln("______________________________________________________________________");
	}
}
