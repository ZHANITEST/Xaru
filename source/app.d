module xaru.app;

import std.stdio;
import xaru.console;
import xaru.params;
import marumaru;
import com.zhanitest.marumaru.unit;

int main(string[] args) {
	// 파라메터 먼저 검증
	Params consoleParams = Params(args);
	
	// 콘솔 초기화
	Console shell = Console(consoleParams);
	shell.showWelcomeMessage();
	makeDir("Downloads");
	
	// 입력한 파라메터에 따라 처리 다름
	if(consoleParams.actionType == ACTION_TYPE.DOWNLOAD) {
		Comic comic = new Comic(consoleParams.value);
		comic.load();

		shell.show("선택된 만화 => "~comic.getTitle());
		foreach(PageLink link; comic.getPageLinks()) {
			writeln(link.name);
		}
	}
	else {
		// ID 입력 또는 입력변수로 받기
		string cmd_id = shell.getUserInput();
	}
	return 0;
}
