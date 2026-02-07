// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernanceToken {
    function getVotingPower(address) external view returns (uint256);
    function stakedBalances(address) external view returns (uint256); // Added this
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
        // Technical Check: User must have at least 50 tokens staked
        // 1000 * 10^18 because of 18 decimals
        require(token.stakedBalances(msg.sender) >= 50 * 10**18, "Must stake 50 GTK to propose");
        
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
}