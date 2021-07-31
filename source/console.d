module xaru.console;

import std.stdio;
import std.string:replace;
import std.array:appender;
import xaru.params;

/***
 * 콘솔관련 구조체
 */
struct Console {
    private static const string VERSION = "0.3A";
    private Params params;
    
    /***
     * 생성자
     * Params:
     *  args = 콘솔 매개변수
     */
    this(Params args) {
        this.params = args;
        initForWindows();
    }

    /***
     * 윈도우용 초기화 옵션
     */
    private static void initForWindows() {
        version(Windows){
            import core.sys.windows.windows;
            SetConsoleOutputCP(CP_UTF8).enforce;
        }
    }

    /***
     * 콘솔에서 입력 얻기
     */
    public string getUserInput() {
		write(">>> ");
		string tmp = readln();
		return tmp.replace("\n", "");
    }

    /***
     * 콘솔출력
     */
    public void show(string message) {
        writeln(message);
    }
    
    /***
     * 웰컴 메세지 출력
     */
    public void showWelcomeMessage() {
        showLine();
        // 빌드모드 명시
        string build_mode = "RELEASE";
        debug
            { build_mode = "DEBUG"; }
        auto sb = appender!string;
        sb.put(" [ xaru ] v");
        sb.put(this.VERSION);
        sb.put("(");
        sb.put(build_mode);
        sb.put(") - Download tool\n Copyleft 2017~2021 ZHANITEST(github.com/zhanitest), LGPL-v2");
        writeln(sb.data);
        showLine();
    }

    public static void showLine() {
        writeln("--------------------------------------------------------------------------------");
    }
}