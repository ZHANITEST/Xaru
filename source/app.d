module main;

import std.stdio;
import xaru;

/// 버전 넘버링
const string ver = "0.25A";


/// 윈도우 CMD에서 한글출력 용도
version(Windows){
	extern(C) int setlocale(int, char*);
	static this(){
		core.stdc.wchar_.fwide(core.stdc.stdio.stdout, 1);
		setlocale(0, cast(char*)"korea");
	}
}

void main(string[] args){
	writeln(" [ xaru.d ] v"~ver~" / Copyleft 2017 zhanitest(.egloos.com) / LGPL v2"); // 라벨
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

	string base_url = "http://marumaru.in/b/manga/"~cmd_id;

	// 회차 얻기
	cartoonLink[] links = scarpChapter(base_url);
	
	// 디스플레이
	writeln("--------------------------------------------------");
	writeln("  [ 제목:"~links[0].title~" ]");
	writeln("--------------------------------------------------");
	uint index = 0;
	foreach( link; links ){
		write("    [");
		write(index);
		write("] : ");
		writeln(text(link.name));
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
		end = links.length;
		writeln( to!string(start)~", "~to!string(end));
	}
	else{
		writeln("옳바르지 않은 명령어 입니다...");
	}

	foreach(link; links[start..end]){
		auto cp = cartoonPage(link);
		cp.download();
	}
}