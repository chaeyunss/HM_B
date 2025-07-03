// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {

    // 컨트랙트 배포자(관리자)의 주소
    address public owner;

    // 안건 정보를 저장하기 위한 구조체
    struct Proposal {
        string description; // 안건 내용
        uint256 forVotes;     // 찬성표 수
        uint256 againstVotes; // 반대표 수
        uint256 creationTime; // 안건 생성 시간
    }

    // 모든 안건들을 저장하는 배열
    Proposal[] public proposals;

    // 특정 주소가 투표권을 가졌는지 기록하는 매핑
    mapping(address => bool) public voters;

    // 각 안건(uint256)에 대해 특정 주소(address)가 이미 투표했는지 기록하는 중첩 매핑
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // 새 안건이 추가되었을 때 발생하는 이벤트
    event ProposalAdded(uint256 proposalId, string description);
    // 투표가 기록되었을 때 발생하는 이벤트
    event Voted(uint256 proposalId, address voter, bool supported);

    // 함수를 오직 owner만 호출할 수 있도록 제한하는 제어자
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 함수를 오직 투표권을 가진 주소만 호출할 수 있도록 제한하는 제어자
    modifier onlyVoter() {
        require(voters[msg.sender], "Only registered voters can call this function");
        _;
    }

    constructor(address[] memory _initialVoters) {
        owner = msg.sender; // 컨트랙트를 배포한 사람을 owner로 설정
        // 전달받은 주소 배열을 순회하며 voters 매핑에 투표권을 부여
        for (uint i = 0; i < _initialVoters.length; i++) {
            voters[_initialVoters[i]] = true;
        }
    }

    function addProposal(string memory _description) public onlyOwner {
        uint256 proposalId = proposals.length; // 새 안건의 ID는 현재 배열의 길이와 같음
        // 새 안건을 생성하고 proposals 배열에 추가
        proposals.push(Proposal({
            description: _description,
            forVotes: 0,
            againstVotes: 0,
            creationTime: block.timestamp // 현재 블록의 타임스탬프를 생성 시간으로 기록
        }));
        emit ProposalAdded(proposalId, _description);
    }

    
    function vote(uint256 _proposalId, bool _supportsProposal) public onlyVoter {
        require(_proposalId < proposals.length, "Proposal does not exist");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        hasVoted[_proposalId][msg.sender] = true; // 투표햇음을 기록

        if (_supportsProposal) {
            proposals[_proposalId].forVotes++; // 찬성표 증가
        } else {
            proposals[_proposalId].againstVotes++; // 반대표 증가
        }
        emit Voted(_proposalId, msg.sender, _supportsProposal);
    }

    function getVoteResult(uint256 _proposalId) public view returns (string memory result) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        
        Proposal storage p = proposals[_proposalId];
        
        // 현재 시간이 안건 생성 시간 + 5분보다 이후인지 확인
        require(block.timestamp >= p.creationTime + 5 minutes, "Voting period is not over yet");

        if (p.forVotes > p.againstVotes) {
            return "Passed";
        } else if (p.forVotes < p.againstVotes) {
            return "Failed";
        } else {
            return "Tie";
        }
    }
}