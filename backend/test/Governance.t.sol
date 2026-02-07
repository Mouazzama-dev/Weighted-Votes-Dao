// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "forge-std/Test.sol";
// import "../src/GovernanceToken.sol";
// import "../src/Governor.sol";

// contract GovernanceTest is Test {
//     GovernanceToken token;
//     Governor governor;
//     address voter = address(0xABC);

//     function setUp() public {
//         vm.warp(1000); // Set a baseline time
//         token = new GovernanceToken();
//         governor = new Governor(address(token));

//         token.transfer(voter, 1000e18);
//     }

//     function test_TimeWeightedVoting() public {
//         // 1. Voter deposits tokens
//         vm.prank(voter);
//         token.deposit(100e18);

//         // 2. Create a proposal
//         governor.createProposal("Improve Protocol", 1 days);

//         // 3. Fast forward time by exactly 10 hours (36,000 seconds)
//         vm.warp(block.timestamp + 10 hours);

//        // 4. Vote
//     vm.prank(voter);
//     governor.vote(0, true);
    
//     // 5. Check results - Fetching the struct and accessing the field directly
//     // This is safer than tuple destructuring for structs with strings
//     uint256 votesFor = governor.getVotesFor(0); 
    
//     uint256 expectedPower = 100e18 * 10 hours;
//     assertEq(votesFor, expectedPower, "Voting power math mismatch");
//     }
// }