// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is ERC20 {
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;
    
    // Events frontend ke liye zaroori hain
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() ERC20("GovToken", "GTK") {
        // Deployer ko 1 million tokens milenge
        _mint(msg.sender, 1000000 * 10**18);
    }

    // --- MINT FUNCTION (For Testing) ---
    // Isse koi bhi naye tokens le sakega dashboard check karne ke liye
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        require(balanceOf(msg.sender) >= _amount, "Not enough GTK tokens");

        // Pehle tokens contract mein transfer honge
        _transfer(msg.sender, address(this), _amount);
        
        // Agar pehle se stake hai, toh purana bonus khatam (time reset)
        stakes[msg.sender] = Stake({
            amount: stakes[msg.sender].amount + _amount,
            startTime: block.timestamp
        });

        emit Staked(msg.sender, _amount);
    }

    function getVotingPower(address account) public view returns (uint256) {
        if (stakes[account].amount == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - stakes[account].startTime;
        
        // FIXED LOGIC: Power = Amount + (Amount * Time in Days)
        // Sirf timeElapsed se multiply karne se number bohat bara ho jata hai
        // Hum 1 din (86400 seconds) ko 1 unit weight maan rahe hain
        uint256 weight = 1 + (timeElapsed / 1 days);
        return stakes[account].amount * weight;
    }

    function withdraw(uint256 _amount) external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= _amount, "Insufficient staked balance");
        
        // Logic: Partial withdraw par bhi time reset hoga (security ke liye)
        userStake.amount -= _amount;
        userStake.startTime = block.timestamp; 

        if(userStake.amount == 0) {
            delete stakes[msg.sender];
        }
        
        _transfer(address(this), msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }
}