// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../Dao.sol";

contract DeployDAO is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the DAO
        DavidsonDAO dao = new DavidsonDAO();
        
        console.log("DAO deployed at:", address(dao));
        console.log("GovernanceToken deployed at:", address(dao.governanceToken()));
        console.log("GovernorContract deployed at:", address(dao.governor()));
        console.log("Timelock deployed at:", address(dao.timelock()));
        console.log("Box deployed at:", address(dao.box()));
        
        vm.stopBroadcast();
    }
} 