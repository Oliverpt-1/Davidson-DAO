// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/GovernanceToken.sol";
import "../Dao.sol";

contract DeployDAO is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the governance token
        GovernanceToken token = new GovernanceToken();
        console.log("GovernanceToken deployed at:", address(token));
        
        // Deploy the DAO
        DavidsonDAO dao = new DavidsonDAO(token);
        console.log("DavidsonDAO deployed at:", address(dao));
        console.log("Box deployed at:", address(dao.box()));
        
        vm.stopBroadcast();
    }
} 