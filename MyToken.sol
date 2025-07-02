// SPDX-License-Identifier: MIT
// 라이선스가 MIT 라이선스임을 명시하는 주석입니다. 컴파일러가 인식.

pragma solidity ^0.8.20;
// 솔리디티 컴파일러 0.8.20 버전 이상에서 컴파일해야 함을 나타넴.

// 'MyToken'이라는 이름의 스마트 컨트랙트를 정의함.
contract MyToken {

    // 컨트랙트의 영구적인 데이터를 저장하는 상태 변수들

    string public name; // 토큰의 전체 이름 (예: "My Token")을 저장할 변수. public으로 선언되어 외부에서 조회가 가능함.
    string public symbol; // 토큰의 심볼 (예: "MTK")을 저장할 변수.
    uint8 public decimals = 18; // 토큰의 소수점 자릿수를 저장함. 1 토큰은 1 * 10^18의 가장 작은 단위로 표현되며, 18이 표준.
    uint256 public totalSupply; // 발행된 토큰의 총량을 저장할 변수.

    // 각 주소(address)가 얼마의 잔액(uint256)을 가지고 있는지 1:1로 매핑하여 저장함.
    // 예: balanceOf[0x123...] = 100 -> 0x123... 주소는 100개의 토큰을 가짐
    mapping(address => uint256) public balanceOf;

    // A주소가 B주소에게 얼마나 인출을 허용했는지 저장하는 중첩 매핑. 매핑 : 키에 값을 짝지어 저장하는것
    // 예: allowance[A][B] = 50 -> A는 B가 자신의 계좌에서 50만큼 빼가는 것을 허용함
    mapping(address => mapping(address => uint256)) public allowance;

    // 토큰이 전송될 때마다 발생하는 이벤트를 정의함. indexed로 선언되어 검색이 용이해짐.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // approve 함수가 성공적으로 호출될 때 발생하는 이벤트를 정의함.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name; // 배포 시 입력받은 인자(_name)로 토큰의 이름을 초기화함.
        symbol = _symbol; // 배포 시 입력받은 인자(_symbol)로 토큰의 심볼을 초기화함.
        
        // 초기 발행량에 소수점 자릿수를 적용하여 최종 총량을 계산함.
        totalSupply = _initialSupply * (10**uint256(decimals));
        // 컨트랙트를 배포한 주소(msg.sender)의 잔액을 총량으로 설정함.
        balanceOf[msg.sender] = totalSupply;
        // 토큰이 처음 발행되었음을 Transfer 이벤트를 통해 블록체인에 기록함. (0번 주소에서 배포자에게로) 0번 주소는 주인이 없는 특별한 주소로, '토큰 생성'을 의미하는 신호로 사용됨.
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    // '_to' 주소로 '_value' 만큼의 토큰을 전송하는 함수.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // 함수를 호출한 사람(msg.sender)의 잔액이 보내려는 금액(_value)보다 크거나 같은지 확인. 그렇지 않으면 오류를 발생시키고 실행을 중단.
        require(balanceOf[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        
        balanceOf[msg.sender] -= _value; // 보내는 사람의 잔액에서 _value 만큼 차감.
        balanceOf[_to] += _value; // 받는 사람의 잔액에 _value 만큼 더함.
        
        // Transfer 이벤트를 발생시켜 트랜잭션 기록을 남김.
        emit Transfer(msg.sender, _to, _value);
        // 함수가 성공적으로 실행되었음을 나타내는 true를 반환.
        return true;
    }

    // '_spender' 주소에게 내 계좌에서 '_value' 만큼의 토큰을 인출할 수 있도록 허용(승인)하는 함수.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 허용량을 allowance 매핑에 기록. (호출자[msg.sender]가 _spender에게 _value만큼 허용)
        allowance[msg.sender][_spender] = _value;
        // Approval 이벤트를 발생시켜 승인 기록을 남김.
        emit Approval(msg.sender, _spender, _value);
        // 성공적으로 실행되었음을 나타내는 true를 반환.
        return true;
    }

    // '_from' 주소의 잔액에서 '_to' 주소로 '_value' 만큼 토큰을 전송하는 함수. (대리 전송)
    // 이 함수는 반드시 approve를 통해 미리 허용된 금액 내에서만 실행 가능함.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 보내는 사람(_from)의 잔액이 충분한지 확인.
        require(balanceOf[_from] >= _value, "ERC20: transfer amount exceeds balance");
        // 이 함수를 호출한 사람(msg.sender)이 _from에게서 _value만큼 인출할 수 있도록 허용받았는지 확인.
        require(allowance[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");

        // 사용한 만큼 허용량을 차감.
        allowance[_from][msg.sender] -= _value;
        // 보내는 사람(_from)의 잔액을 차감.
        balanceOf[_from] -= _value;
        // 받는 사람(_to)의 잔액을 더함.
        balanceOf[_to] += _value;

        // Transfer 이벤트를 발생시켜 트랜잭션 기록을 남김.
        emit Transfer(_from, _to, _value);
        // 성공적으로 실행되었음을 나타내는 true를 반환.
        return true;
    }
}