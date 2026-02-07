// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernanceToken {
    IERC20 public token;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakedAt;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        token.transferFrom(msg.sender, address(this), amount);
        
        stakedBalances[msg.sender] += amount;
        stakedAt[msg.sender] = block.timestamp; // Time resets on new deposit
    }

    // --- NEW WITHDRAW FUNCTION ---
    function withdraw(uint256 amount) external {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        
        stakedBalances[msg.sender] -= amount;
        
        // Agar saare tokens nikal liye toh time reset, 
        // warna partial withdraw par bhi penalty (security reasons)
        stakedAt[msg.sender] = block.timestamp; 

        token.transfer(msg.sender, amount);
    }

    function getVotingPower(address account) public view returns (uint256) {
        uint256 duration = block.timestamp - stakedAt[account];
        if (stakedBalances[account] == 0) return 0;
        
        // Power = Amount * Time (simplified time-weight logic)
        return stakedBalances[account] * (1 + duration / 1 days);
    }
}