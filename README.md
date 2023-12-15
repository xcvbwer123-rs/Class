# 쓰는법
## 만들기
class.create 함수를 통해 새로운 클래스를 생성할 수 있습니다.

create 안에는 클래스의 정보를 담는 테이블이 들어갑니다.

이름 앞에 별이 붙어 있는 값들은 꼭 필요한 값입니다.

```
속성 테이블 {
    \*value: 속성의 기본값입니다.
    isReadOnly: boolean값이며 없어도 크게 문제가 되지 않습니다. class.create를 사용하지 않은 다른 스크립트에서 해당 속성값을 바꾸려고 시도하면 오류를 반환합니다. (기본값 = false)
}

클래스 정보 테이블 {
    \*className: tostring 값을 사용했을 때 표시될 스트링입니다. ***type(), typeof() 같은 함수를 사용해도 해당 값은 반환되지 않습니다.***
    \*properties: *{[속성 이름] = 속성 테이블}* 이런 형태로 들어가는 테이블입니다.
    methods: *{[메서드 이름] = 함수}* 이런 형태로 들어가는 테이블입니다. 함수의 첫 번째 인자로 클래스가 들어옵니다.
    getters: *{[속성 이름] = 함수}* 이런 형태로 들어가는 테이블입니다. 함수의 첫 번째 인자로 클래스, 함수의 2번째 인자로 현제의 속성값이 들어옵니다. ***함수는 무조건 값을 반환해야 합니다. (아닐 시 nil값이 반환됨)***
    setters: *{[속성 이름] = 함수}* 이런 형태로 들어가는 테이블입니다. 함수의 첫 번째 인자로 클래스, 함수의 2번째 인자로 새로 설정될 속성값이 들어옵니다. ***함수는 무조건 값을 반환해야 합니다. (아닐 시 nil값이 저장됨)***
    metamethods: 추가로 씌워질 메타 메서드들이 들어가는 테이블입니다.
    makeAsUserdata: 클래스를 newproxy()로 만들 것인지에 대한 boolean 값입니다.
}
```

## 추가 속성
create함수를 사용하면 클래스 생성자를 반환합니다. `생성자.new()`를 통해 새로운 클래스 오브젝트를 생성할수 있습니다.

새로 추가되는 속성, 메소드 들은 다음과 같습니다.

```
-- 속성
[string] .className | 지정해줬던 className값입니다. 어느 스크립트에서도 수정할수 없습니다. 수정하려고 시도할시 에러를 반환합니다.

[RBXScriptSignal] .Changed -> (property: string, newValue: any, oldValue: any?) | 로블록스 Instance의 Changed이벤트와 유사합니다. 값이 바뀌었을때 속성이름, 새 값, 예전값이 들어옵니다.

-- 메소드
:Destroy() -> () | 오브젝트를 정리합니다. 호출될경우 빈 테이블이나 빈 userdata값이 됩니다.

:GetPropertyChangedSignal(propertyName: string) -> RBXScriptSignal | 로블록스 Instance의 GetPropertyChangedSignal메소드와 유사합니다. 값이 바뀌었을때 발동되는 시그널을 반환합니다. 이 시그널은 새 값, 예전값이 들어옵니다.
```

## 클래스 상속
`모듈.super`함수나 `생성자:super`메소드를 통해서 클래스를 상속시킬수 있습니다.

필요한 인자들은 다음과 같습니다.

#### 모듈.super
```
모듈.super(부모가 될 클래스, 덮어씌울 정보 테이블) -> 상속된 클래스
```

#### 생성자:super
```
생성자:super(덮어씌울 정보 테이블) -> 상속된 클래스
```

## 예시
```lua
local class = require(클래스 모듈 위치)

-- 클래스 생성
local myClass = class.create({
    className = "myClass";

    properties = {
        Property1 = {
            value = 10;
        };

        Property2 = {
            value = true;
        };
    };

    methods = {
        Jump = function(self)
            print("jumped")
        end;
    };

    getters = {
        Property1 = function(self, value: number)
            -- 내부에서 해당값을 호출해도 스텍 오버플로우가 생기지는 않습니다. 하지만 value와 같은값이 들어옵니다.
            local CurrentValue = self.Property1 -- 그니까 굳이 하지 마세요.


            return value + 40
        end;

        Property2 = function(self, value: boolean)
            -- 있는값의 반대로 돌려줍니다.
            return not value
        end;
    };
    
    setters = {
        Property1 = function(self, value)
            -- 이런식으로 setter 안에서 같은 인덱스를 수정하려고 하면 스텍 오버플로우를 피하기 위해 해당 라인이 무시됩니다.
            self.Property1 = 10 -- 그리고 이 라인에서 경고를 띄웁니다.

            -- 이렇게 인덱스가 다르면 수정할수 있습니다.
            self.Property2 = false

            return value
        end;

        Property2 = function(self, value)
            -- 들어오는 새 변수를 반대로 저장합니다.
            return not value
        end;
    };

    metamethods = {
        __tostring = function() return "myClass" end;
    };
})

-- 오브젝트 생성
local myObject = myClass.new()

-- 변수 수정
myObject.Property1 = 20

```

## 대충 더 할말
클래스만들때 정의 안한 변수 새로 넣어도 에러 안나요 :>

```lua
local myClass = 모듈.create({
    className = "myClass";
    properties = {
        OriginalProperty = {
            value = "Original"
        }
    };
})

local classObject = myClass.new()
classObject.ExtraProperty = "Extra"

print(`Original Property : {classObject.OriginalProperty}`)
print(`Extra Property : {classObject.ExtraProperty}`)
```

이런식으로 말이죠!