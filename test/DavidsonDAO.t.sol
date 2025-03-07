// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GovernanceToken.sol";
import "../Dao.sol";
import "../contracts/Box.sol";

contract DavidsonDAOTest is Test {
    GovernanceToken public token;
    DavidsonDAO public dao;
    Box public box;
    
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    function setUp() public {
        vm.startPrank(deployer);
        
        // Deploy token
        token = new GovernanceToken();
        
        // Deploy DAO
        dao = new DavidsonDAO(token);
        
        // Get Box
        box = dao.box();
        
        // Transfer tokens to users
        token.transfer(user1, 100 ether);
        token.transfer(user2, 50 ether);
        
        // Users delegate to themselves
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.delegate(user1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.delegate(user2);
        vm.stopPrank();
    }
    
    function testProposalCreation() public {
        vm.startPrank(user1);
        
        // Create a proposal to update the treasury
        bytes memory callData = abi.encodeWithSelector(
            box.updateTreasury.selector,
            1000 ether
        );
        
        uint256 proposalId = dao.propose(
            "Update Treasury",
            "Set the treasury balance to 1000 ether",
            address(box),
            callData
        );
        
        // Check proposal was created
        (
            address proposer,
            string memory title,
            ,
            address target,
            ,
            ,
            ,
            ,
            bool executed
        ) = dao.getProposal(proposalId);
        
        assertEq(proposer, user1, "Proposer should be user1");
        assertEq(title, "Update Treasury", "Title should match");
        assertEq(target, address(box), "Target should be box");
        assertEq(executed, false, "Proposal should not be executed");
        
        vm.stopPrank();
    }
    
    function testVoting() public {
        // Create a proposal
        vm.startPrank(user1);
        bytes memory callData = abi.encodeWithSelector(
            box.updateTreasury.selector,
            1000 ether
        );
        
        uint256 proposalId = dao.propose(
            "Update Treasury",
            "Set the treasury balance to 1000 ether",
            address(box),
            callData
        );
        vm.stopPrank();
        
        // Vote on the proposal
        vm.startPrank(user1);
        dao.castVote(proposalId, true); // Vote in favor
        vm.stopPrank();
        
        vm.startPrank(user2);
        dao.castVote(proposalId, false); // Vote against
        vm.stopPrank();
        
        // Check that votes were recorded
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 votesFor,
            uint256 votesAgainst,
            
        ) = dao.getProposal(proposalId);
        
        assertEq(votesFor, 100 ether, "Votes for should be 100 ether");
        assertEq(votesAgainst, 50 ether, "Votes against should be 50 ether");
        
        // Check that users have voted
        assertTrue(dao.hasVoted(proposalId, user1), "User1 should have voted");
        assertTrue(dao.hasVoted(proposalId, user2), "User2 should have voted");
    }
    
    function testProposalExecution() public {
        // Create a proposal
        vm.startPrank(user1);
        bytes memory callData = abi.encodeWithSelector(
            box.updateTreasury.selector,
            1000 ether
        );
        
        uint256 proposalId = dao.propose(
            "Update Treasury",
            "Set the treasury balance to 1000 ether",
            address(box),
            callData
        );
        
        // Vote on the proposal
        dao.castVote(proposalId, true); // Vote in favor
        vm.stopPrank();
        
        // Wait for voting to end
        vm.roll(block.number + dao.VOTING_PERIOD() + 1);
        
        // Execute the proposal
        vm.startPrank(user1);
        dao.execute(proposalId);
        vm.stopPrank();
        
        // Check that the proposal was executed
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool executed
        ) = dao.getProposal(proposalId);
        
        assertTrue(executed, "Proposal should be executed");
        
        // Check that the treasury was updated
        assertEq(box.getTreasuryBalance(), 1000 ether, "Treasury should be updated");
    }
    
    function testProposalStates() public {
        // Create a proposal
        vm.startPrank(user1);
        bytes memory callData = abi.encodeWithSelector(
            box.updateTreasury.selector,
            1000 ether
        );
        
        uint256 proposalId = dao.propose(
            "Update Treasury",
            "Set the treasury balance to 1000 ether",
            address(box),
            callData
        );
        
        // Check state: Active
        assertEq(dao.state(proposalId), 1, "Proposal should be active");
        
        // Vote on the proposal
        dao.castVote(proposalId, true); // Vote in favor
        vm.stopPrank();
        
        // Wait for voting to end
        vm.roll(block.number + dao.VOTING_PERIOD() + 1);
        
        // Check state: Succeeded
        assertEq(dao.state(proposalId), 3, "Proposal should have succeeded");
        
        // Execute the proposal
        vm.startPrank(user1);
        dao.execute(proposalId);
        vm.stopPrank();
        
        // Check state: Executed
        assertEq(dao.state(proposalId), 4, "Proposal should be executed");
    }
} 