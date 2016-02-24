# Xaru
순수하게 **D언어**와 **표준라이브러리(phobos)**로만 작성된 파서 입니다. 거의 모든 것이 Regex로 이루어져 있습니다.



# 예제
## 만화 검색
```
import std.stdio; import Xaru;
void main()
{
	auto bot = new MaruMaru();
	foreach( element; bot.search("보쿠걸") )
		{ writeln( element ); }
	write("===== Done! =====");
}
```

result:
```
["보쿠걸":"/b/manga/16"]
===== Done! =====
```

## 만화 이미지파일 URL들 얻어오기
```
import std.stdio; import Xaru;
void main()
{
	auto bot = new Cartoon("16");
	foreach( e; bot.getImageUrls("보쿠걸 94화") )
		{ writeln(e); }
}
```

result:
```
http://www.shencomics.com/wp-content/uploads/2016/01/m03616.jpg
http://www.shencomics.com/wp-content/uploads/2016/01/m03627.jpg
http://www.shencomics.com/wp-content/uploads/2016/01/m03635.jpg
... 중략
```



# 라이센스
**오픈소스**
 * LGPL v2.1(Xaru)
 * BSD(phantomJS)



# 빌드
준비물
  1. DMD 2.0.*버전의 컴파일러
  2. Git
  3. PhantomJS: http://phantomjs.org
터미널에 입력 후 xaru 경로에 phantomjs 복사.
```
git clone https://github.com/zhanitest/xaru.git
cd xaru
dmd xaru
```



# TODO
  1. support "SlimerJS"
  2. password process
  3. Refactoring
  4. Linux(*buntu)
