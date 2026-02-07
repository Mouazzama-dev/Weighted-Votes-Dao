// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Interface ko naye token structure (Stake struct) ke mutabiq update kiya hai
interface IGovernanceToken {
    function getVotingPower(address account) external view returns (uint256);
    // GovernanceToken mein 'stakes' mapping public hai, isliye Solidity auto-getter banati hai
    // Jo (uint256 amount, uint256 startTime) return karta hai
    function stakes(address account) external view returns (uint256 amount, uint256 startTime);
}

contract Governor {
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    IGovernanceToken public token;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 id, string description);

    constructor(address _tokenAddress) {
        token = IGovernanceToken(_tokenAddress);
    }

    function createProposal(string calldata _description, uint256 _duration) external {
        // FIX: Mapping ki bajaye ab hum struct se 'amount' nikaal rahe hain
        (uint256 stakedAmount, ) = token.stakes(msg.sender);
        
        // 50 GTK check (50 * 10^18)
        require(stakedAmount >= 50 * 10**18, "Must stake 50 GTK to propose");
        
        proposals.push(Proposal({
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + _duration,
            executed: false
        }));
        
        emit ProposalCreated(proposals.length - 1, _description);
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.endTime, "Voting ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 weight = token.getVotingPower(msg.sender);
        require(weight > 0, "No voting power");

        if (_support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }

        hasVoted[_proposalId][msg.sender] = true;
    }

    // Helper function taake frontend asaani se total proposals count le sake
    function getProposalsCount() external view returns (uint256) {
        return proposals.length;
    }
}