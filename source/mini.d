module mini;
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

class miniapp{
    string index;
    this(string index){
        this.index = index;
    }

    void download(){
        comic c = comic();
        string[string] info = c.getInfo("http://wasabisyrup.com/archives/"~this.index);
        string[] file_urls = c.getFileUrl("http://wasabisyrup.com/archives/"~this.index);
        string title = info["TITLE"];

		string path = "./download/["~this.index~"]"~stripChar(title)~"/";
        makeDir(path);
        writeln("다운로드 시작: "~title);
        foreach(furl; parallel(file_urls) ){
			auto rq = Request();
			auto ds = rq.get(uri.encode(furl));
			
            // 파일이름 따기
            string file_name = furl.split("/")[$-1];
			std.file.write(
				path~file_name,
				ds.responseBody.data
			);
		}
		writeln("______________________________________________________________________");
    }
}