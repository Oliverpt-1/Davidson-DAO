// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GovernanceToken.sol";
import "../Dao.sol";
import "../contracts/Box.sol";
import "../contracts/MembershipNFT.sol";

contract DavidsonDAOTest is Test {
    GovernanceToken public token;
    DavidsonDAO public dao;
    Box public box;
    MembershipNFT public membershipNFT;
    
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    function setUp() public {
        vm.startPrank(deployer);
        
        // Deploy token
        token = new GovernanceToken();
        
        // Deploy DAO
        dao = new DavidsonDAO(token);
        
        // Get Box and MembershipNFT
        box = dao.box();
        membershipNFT = dao.membershipNFT();
        
        // Transfer tokens to users - give enough to meet the proposal threshold
        // The threshold is 1% of total supply (10,000 tokens)
        token.transfer(user1, 100000 ether); // 100,000 tokens
        token.transfer(user2, 50000 ether);  // 50,000 tokens
        token.transfer(user3, 25000 ether);  // 25,000 tokens
        
        // Users delegate to themselves
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.delegate(user1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.delegate(user2);
        vm.stopPrank();
        
        vm.startPrank(user3);
        token.delegate(user3);
        vm.stopPrank();
        
        // Move forward a block to activate voting power
        vm.roll(block.number + 1);
        
        // Verify and issue membership NFTs to user1 and user2
        vm.startPrank(address(dao));
        dao.verifyMember(user1);
        dao.verifyMember(user2);
        dao.issueMembership(user1, "ipfs://QmUser1Metadata");
        dao.issueMembership(user2, "ipfs://QmUser2Metadata");
        vm.stopPrank();
    }
    
    function testMembershipVerification() public {
        // Check that user1 and user2 are verified and have membership NFTs
        assertTrue(membershipNFT.isVerified(user1), "User1 should be verified");
        assertTrue(membershipNFT.isVerified(user2), "User2 should be verified");
        assertTrue(membershipNFT.hasMembership(user1), "User1 should have membership NFT");
        assertTrue(membershipNFT.hasMembership(user2), "User2 should have membership NFT");
        
        // Check that user3 is not verified and doesn't have a membership NFT
        assertFalse(membershipNFT.isVerified(user3), "User3 should not be verified");
        assertFalse(membershipNFT.hasMembership(user3), "User3 should not have membership NFT");
    }
    
    function testBatchVerification() public {
        // Create an array of addresses to verify
        address[] memory members = new address[](2);
        members[0] = user3;
        members[1] = address(5);
        
        // Batch verify the members
        vm.startPrank(address(dao));
        dao.batchVerifyMembers(members);
        vm.stopPrank();
        
        // Check that the members are verified
        assertTrue(membershipNFT.isVerified(user3), "User3 should be verified");
        assertTrue(membershipNFT.isVerified(address(5)), "Address 5 should be verified");
    }
    
    function testMembershipRequirement() public {
        // Try to create a proposal as user3 (who doesn't have a membership NFT)
        vm.startPrank(user3);
        
        bytes memory callData = abi.encodeWithSelector(
            box.updateTreasury.selector,
            1000 ether
        );
        
        // This should revert because user3 doesn't have a membership NFT
        vm.expectRevert("DavidsonDAO: proposer must be a member");
        dao.propose(
            "Update Treasury",
            "Set the treasury balance to 1000 ether",
            address(box),
            callData
        );
        
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
        
        // Try to vote as user3 (who doesn't have a membership NFT)
        vm.startPrank(user3);
        vm.expectRevert("DavidsonDAO: voter must be a member");
        dao.castVote(proposalId, true);
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
        
        assertEq(votesFor, 100000 ether, "Votes for should be 100000 ether");
        assertEq(votesAgainst, 50000 ether, "Votes against should be 50000 ether");
        
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
    
    function testMemberVerificationProposal() public {
        // Create a proposal to verify user3
        vm.startPrank(user1);
        
        bytes memory callData = abi.encodeWithSelector(
            dao.verifyMember.selector,
            user3
        );
        
        uint256 proposalId = dao.propose(
            "Verify New Member",
            "Verify user3 as a member of the DAO",
            address(dao),
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
        
        // Check that user3 is now verified
        assertTrue(membershipNFT.isVerified(user3), "User3 should be verified after proposal execution");
    }
    
    function testMembershipIssuanceProposal() public {
        // First verify user3's membership eligibility
        vm.startPrank(address(dao));
        dao.verifyMember(user3);
        vm.stopPrank();
        
        // Create a proposal to issue membership to user3
        vm.startPrank(user1);
        
        bytes memory callData = abi.encodeWithSelector(
            dao.issueMembership.selector,
            user3,
            "ipfs://QmUser3Metadata"
        );
        
        uint256 proposalId = dao.propose(
            "Issue Membership",
            "Issue membership NFT to user3",
            address(dao),
            callData
        );
        
        // Vote on the proposal
        dao.castVote(proposalId, true); // Vote in favor
        vm.stopPrank();
        
        vm.startPrank(user2);
        dao.castVote(proposalId, true); // Vote in favor
        vm.stopPrank();
        
        // Wait for voting to end
        vm.roll(block.number + dao.VOTING_PERIOD() + 1);
        
        // Execute the proposal
        vm.startPrank(user1);
        dao.execute(proposalId);
        vm.stopPrank();
        
        // Check that user3 now has a membership NFT
        assertTrue(membershipNFT.hasMembership(user3), "User3 should have a membership NFT after proposal execution");
    }
} 