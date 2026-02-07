// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GovernanceToken.sol";
import "../src/Governor.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. GovernanceToken khud token hai, isay kisi address ki zaroorat nahi
        // Constructor arguments zero hain (expected 0, giving 0)
        GovernanceToken govToken = new GovernanceToken();

        // 2. Governor ko GovToken ka address dein taake wo power check kar sake
        Governor governor = new Governor(address(govToken));

        console.log("GovernanceToken Address:", address(govToken));
        console.log("Governor Address:", address(governor));

        vm.stopBroadcast();
    }
}