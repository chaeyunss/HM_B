// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract piggybank {
    mapping (address => uint256) public balances;
    
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 _amount) public {
        // 출금하려는 금액이 현재 잔액보다 많지 않은지 확인함.
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;

        // 함수를 호출한 사람(msg.sender)에게 _amount 만큼의 이더를 보냄
        // 전송에 실패하면 트랜잭션 전체가 원래대로 되돌아감.
        payable(msg.sender).transfer(_amount);
    }
}