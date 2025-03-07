// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Dao.sol";
import "../contracts/GovernanceToken.sol";
import "../contracts/Governance Standard/GovernorContract.sol";
import "../contracts/Governance Standard/Timelock.sol";
import "../contracts/Box.sol";

contract DavidsonDAOTest is Test {
    DavidsonDAO public dao;
    GovernanceToken public token;
    GovernorContract public governor;
    Timelock public timelock;
    Box public box;
    
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    function setUp() public {
        vm.startPrank(deployer);
        dao = new DavidsonDAO();
        
        // Get deployed contracts
        token = dao.governanceToken();
        governor = dao.governor();
        timelock = dao.timelock();
        box = dao.box();
        
        vm.stopPrank();
    }
    
    function testDAODeployment() public {
        // Check that all contracts are deployed
        assertTrue(address(token) != address(0), "Token not deployed");
        assertTrue(address(governor) != address(0), "Governor not deployed");
        assertTrue(address(timelock) != address(0), "Timelock not deployed");
        assertTrue(address(box) != address(0), "Box not deployed");
        
        // Check that the box is owned by the timelock
        assertEq(box.owner(), address(timelock), "Box not owned by timelock");
        
        // Check that the governor has the proposer role
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)), "Governor doesn't have proposer role");
        
        // Check that anyone can execute
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), "Anyone can't execute");
        
        // Check that deployer doesn't have admin role anymore
        assertFalse(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), deployer), "Deployer still has admin role");
    }
    
    function testTokenDistribution() public {
        // Check that the deployer has all tokens
        assertEq(token.balanceOf(deployer), token.s_maxSupply(), "Deployer doesn't have all tokens");
        
        // Transfer tokens to users
        vm.startPrank(deployer);
        token.transfer(user1, 1000 ether);
        token.transfer(user2, 500 ether);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), 1000 ether, "User1 didn't receive tokens");
        assertEq(token.balanceOf(user2), 500 ether, "User2 didn't receive tokens");
    }
} 