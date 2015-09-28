# 자루(Xaru)
API for "http://marumaru.in".

  1. 순수하게 D언어와 표준라이브러리(phobos) 작성되었습니다.
  2. 오픈소스(LGPL v2)입니다.
  3. 제대로 된 HTML파서 없이 Regex 땜질로 이루어져있습니다.



# How to build it?
Requirement: DMD 2.0.*, Git
```
git clone https://github.com/zhanitest/xaru.git
cd xaru
dmd xaru
```



# Requirement
PhantomJS: http://phantomjs.org



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
  1. support SlimerJS
  2. Refactoring(lol)



# 라이센스(License)
LGPL v2.1
