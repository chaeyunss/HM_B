// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultisigWallet {
    event TransactionAdded(uint256 txId, address to, uint256 value, bytes data);
    event TransactionApproved(uint256 txId, address approver);
    event TransactionExecuted(uint256 txId);

    address public owner; // 컨트랙트 배포자
    uint256 public requiredApprovals; // 트랜잭션 실행에 필요한 최소 승인 수
    
    // 제안된 트랜잭션 정보를 담는 구조체
    struct Transaction {
        address to;      // 보낼 주소
        uint256 value;   // 보낼 이더(wei)
        bytes data;      // 함께 실행할 데이터 (예: 함수 호출)
        bool executed;   // 실행 여부
        uint256 approvalCount; // 받은 승인 수
    }

    Transaction[] public transactions; // 모든 트랜잭션 제안을 저장하는 배열
    mapping(address => bool) public isApprover; // 승인권자 목록
    mapping(uint256 => mapping(address => bool)) public hasApproved; // 각 트랜잭션(ID)에 대해 누가 승인했는지 기록

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address[] memory _initialApprovers, uint256 _required) {
        require(_initialApprovers.length > 0, "At least one approver required");
        require(_required > 0 && _required <= _initialApprovers.length, "Invalid number of required approvals");

        owner = msg.sender;
        requiredApprovals = _required;

        for (uint i = 0; i < _initialApprovers.length; i++) {
            isApprover[_initialApprovers[i]] = true;
        }
    }

    function addTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        uint256 txId = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            approvalCount: 0
        }));
        emit TransactionAdded(txId, _to, _value, _data);
    }

    function approveTransaction(uint256 _txId, bytes memory _signature) public {
        require(_txId < transactions.length, "Transaction does not exist");
        Transaction storage txToApprove = transactions[_txId];
        require(!txToApprove.executed, "Transaction already executed");

        // 1. 서명해야 할 메시지 해시를 계약 내부에서 동일하게 생성.
        bytes32 messageHash = getMessageHash(_txId, txToApprove.to, txToApprove.value, txToApprove.data);
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // 2. 서명과 메시지 해시를 이용해 서명자의 주소를 복원.
        address signer = recoverSigner(prefixedHash, _signature);
        
        // 3. 복원된 주소가 유효한 승인권자인지, 그리고 아직 승인하지 않았는지 확인.
        require(isApprover[signer], "Signer is not an approver");
        require(!hasApproved[_txId][signer], "Already approved");

        // 4. 승인 상태를 업데이트.
        hasApproved[_txId][signer] = true;
        txToApprove.approvalCount++;
        emit TransactionApproved(_txId, signer);
    }
   
    function executeTransaction(uint256 _txId) public {
        require(_txId < transactions.length, "Transaction does not exist");
        Transaction storage txToExecute = transactions[_txId];
        require(!txToExecute.executed, "Transaction already executed");
        require(txToExecute.approvalCount >= requiredApprovals, "Not enough approvals");

        txToExecute.executed = true; // 실행되었음을 표시
        
        // 실제 트랜잭션을 실행.
        (bool success, ) = txToExecute.to.call{value: txToExecute.value}(txToExecute.data);
        require(success, "Transaction execution failed");
        
        emit TransactionExecuted(_txId);
    }

    
    function getMessageHash(uint256 _txId, address _to, uint256 _value, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_txId, _to, _value, _data));
    }

    
    function recoverSigner(bytes32 _prefixedHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_prefixedHash, v, r, s);
    }


    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}