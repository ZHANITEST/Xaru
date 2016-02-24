# Xaru
API for "http://marumaru.in".
순수하게 D 프로그래밍 언어와 표준라이브러리(phobos)로만 작성된 파서 입니다. 거의 모든 것이 Regex로 이루어져있습니다.



# License
 * LGPL v2.1(Xaru)
 * BSD(phantomJS)



# How to build it?
  1. DMD 2.0.*
  2. Git
  3. PhantomJS: http://phantomjs.org
```
git clone https://github.com/zhanitest/xaru.git
cd xaru
dmd xaru
```



# Example
bot.d
```
import std.stdio;
import Xaru;
void main(){
	auto bot = new MaruMaru();
	foreach( element; bot.search("보쿠걸") ){
		writeln( element );
	}
	write("===== Done! =====");
}
```

result:
```
["보쿠걸":"/b/manga/16"]
===== Done! =====
```



# TODO
  1. support "SlimerJS"
  2. password process
  3. Refactoring
  4. Linux(*buntu)
