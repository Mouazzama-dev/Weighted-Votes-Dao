// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is ERC20 {
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;
    event PowerUpdated(address indexed voter, uint256 newPower);

    constructor() ERC20("GovToken", "GTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        
        // If they already have a stake, the time-weight resets 
        // (A more complex version would use checkpoints)
        _transfer(msg.sender, address(this), _amount);
        
        stakes[msg.sender] = Stake({
            amount: stakes[msg.sender].amount + _amount,
            startTime: block.timestamp
        });
    }

    function getVotingPower(address account) public view returns (uint256) {
    if (stakes[account].amount == 0) return 0;
    
    // Logic: Power = Amount * Time Elapsed
    uint256 timeElapsed = block.timestamp - stakes[account].startTime;
    return stakes[account].amount * timeElapsed;
}

    function withdraw() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake");
        
        uint256 amount = userStake.amount;
        delete stakes[msg.sender];
        _transfer(address(this), msg.sender, amount);
    }
}