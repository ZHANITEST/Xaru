module xaru.params;

/***
 * 명령어 의미 열거형
 */
enum ACTION_TYPE {
    SEARCH,     /// 검색
    DOWNLOAD    /// 다운로드
}

/***
 * 명령어 타입정의 구조체
 */
struct Command {
    private string Rkey;
    private int RminLength;
    private ACTION_TYPE RactionType;

    @property public int minLength() { return this.RminLength; }
    @property public ACTION_TYPE actionType() { return this.RactionType; }
    
    /***
     * 생성자
     * Parmas:
     *  actionType = 커맨트의 성격
     *  key = 키 값 문자열
     *  minLength = 최소 길이
     */
    this(ACTION_TYPE actionType, string key, int minLength) {
        this.Rkey = key;
        this.RminLength = minLength;
        this.RactionType = actionType;
    }
}

/***
 * 파라메터 해석 구조체
 *
 * 콘솔로 입력받은 매개변수에 대해 정의한다.
 */
struct Params {
    private string Rvalue;
    private ulong Rlength;
    private ACTION_TYPE RactionType;

    @property string value() { return Rvalue; }
    @property ulong length() { return Rlength; }
    @property public ACTION_TYPE actionType() { return this.RactionType; }
    
    /***
     * 생성자
     */
    this(string[] args) {
        this.Rlength = args.length;

        // 사전에 정의된 커맨드 리스트
        Command[] commandList = [
            Command(ACTION_TYPE.DOWNLOAD, "S", 2)
        ];

        if(checkParamsEmpty()) {
            throw new Exception("Params is empty...");
        }

        bool matched = false;
        foreach(command; commandList) {
            if(args[1] == "-"~command.Rkey && args.length >= command.RminLength+1) {
                import std.stdio;
                writef("match!! :: ");
                writeln(command);
                matched = true;
                this.RactionType = command.actionType;
                this.Rvalue = args[2];
            }
        }
        if(!matched) {
            throw new Exception("Unknown Params");
        }
    }

    /***
     * 파라메터 길이 검사
     */
    public bool checkParamsEmpty() {
        return (this.Rlength <= 1);
    }
}