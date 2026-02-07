// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GovernanceToken.sol";
import "../src/Governor.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GovernanceToken token = new GovernanceToken();
        new Governor(address(token));

        vm.stopBroadcast();
    }
}