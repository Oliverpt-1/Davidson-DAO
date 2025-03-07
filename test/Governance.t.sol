// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Dao.sol";
import "../contracts/GovernanceToken.sol";
import "../contracts/Governance Standard/GovernorContract.sol";
import "../contracts/Governance Standard/Timelock.sol";
import "../contracts/Box.sol";

contract GovernanceTest is Test {
    DavidsonDAO public dao;
    GovernanceToken public token;
    GovernorContract public governor;
    Timelock public timelock;
    Box public box;
    
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant MIN_DELAY = 3600;
    
    function setUp() public {
        vm.startPrank(deployer);
        dao = new DavidsonDAO();
        
        // Get deployed contracts
        token = dao.governanceToken();
        governor = dao.governor();
        timelock = dao.timelock();
        box = dao.box();
        
        // Distribute tokens
        token.transfer(user1, 100 ether);
        token.transfer(user2, 100 ether);
        token.transfer(user3, 100 ether);
        
        vm.stopPrank();
        
        // Users delegate their voting power to themselves
        vm.startPrank(user1);
        token.delegate(user1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.delegate(user2);
        vm.stopPrank();
        
        vm.startPrank(user3);
        token.delegate(user3);
        vm.stopPrank();
    }
    
    function testProposalLifecycle() public {
        // Create a proposal to update the treasury
        uint256 newTreasuryBalance = 1000 ether;
        
        // Encode the function call
        bytes memory encodedFunctionCall = abi.encodeWithSelector(
            box.updateTreasury.selector,
            newTreasuryBalance
        );
        
        // Create the proposal
        vm.startPrank(user1);
        
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Update treasury balance to 1000 ether";
        
        targets[0] = address(box);
        values[0] = 0;
        calldatas[0] = encodedFunctionCall;
        
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        
        vm.stopPrank();
        
        // Check proposal state (Pending)
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Pending), "Proposal should be pending");
        
        // Wait for the voting delay
        vm.roll(block.number + VOTING_DELAY + 1);
        
        // Check proposal state (Active)
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Active), "Proposal should be active");
        
        // Vote on the proposal
        vm.startPrank(user1);
        governor.castVote(proposalId, 1); // Vote in favor
        vm.stopPrank();
        
        vm.startPrank(user2);
        governor.castVote(proposalId, 1); // Vote in favor
        vm.stopPrank();
        
        vm.startPrank(user3);
        governor.castVote(proposalId, 0); // Vote against
        vm.stopPrank();
        
        // Wait for the voting period to end
        vm.roll(block.number + VOTING_PERIOD + 1);
        
        // Check proposal state (Succeeded)
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Succeeded), "Proposal should have succeeded");
        
        // Queue the proposal
        vm.startPrank(user1);
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.stopPrank();
        
        // Check proposal state (Queued)
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Queued), "Proposal should be queued");
        
        // Wait for the timelock delay
        vm.warp(block.timestamp + MIN_DELAY + 1);
        
        // Execute the proposal
        vm.startPrank(user1);
        governor.execute(targets, values, calldatas, descriptionHash);
        vm.stopPrank();
        
        // Check proposal state (Executed)
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Executed), "Proposal should be executed");
        
        // Check that the treasury balance was updated
        assertEq(box.getTreasuryBalance(), newTreasuryBalance, "Treasury balance should be updated");
    }
    
    function testCreateProjectProposal() public {
        // First, update the treasury to have funds
        uint256 treasuryAmount = 1000 ether;
        
        vm.startPrank(deployer);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        
        targets[0] = address(box);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(box.updateTreasury.selector, treasuryAmount);
        
        string memory description = "Update treasury";
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();
        
        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);
        
        // Vote
        vm.startPrank(deployer);
        governor.castVote(proposalId, 1);
        vm.stopPrank();
        
        // Wait for voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        
        // Queue and execute
        vm.startPrank(deployer);
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + MIN_DELAY + 1);
        governor.execute(targets, values, calldatas, descriptionHash);
        vm.stopPrank();
        
        // Now create a proposal to fund a project
        string memory projectName = "Blockchain Workshop Series";
        string memory projectDescription = "Weekly workshops teaching blockchain fundamentals";
        uint256 projectFunding = 100 ether;
        
        vm.startPrank(user1);
        
        address[] memory projectTargets = new address[](1);
        uint256[] memory projectValues = new uint256[](1);
        bytes[] memory projectCalldatas = new bytes[](1);
        
        projectTargets[0] = address(box);
        projectValues[0] = 0;
        projectCalldatas[0] = abi.encodeWithSelector(
            box.createProject.selector,
            projectName,
            projectDescription,
            projectFunding
        );
        
        string memory projectProposalDescription = "Proposal: Fund Blockchain Workshop Series";
        uint256 projectProposalId = governor.propose(projectTargets, projectValues, projectCalldatas, projectProposalDescription);
        vm.stopPrank();
        
        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);
        
        // Vote
        vm.startPrank(user1);
        governor.castVote(projectProposalId, 1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        governor.castVote(projectProposalId, 1);
        vm.stopPrank();
        
        // Wait for voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        
        // Queue and execute
        vm.startPrank(user1);
        bytes32 projectDescriptionHash = keccak256(bytes(projectProposalDescription));
        governor.queue(projectTargets, projectValues, projectCalldatas, projectDescriptionHash);
        vm.warp(block.timestamp + MIN_DELAY + 1);
        governor.execute(projectTargets, projectValues, projectCalldatas, projectDescriptionHash);
        vm.stopPrank();
        
        // Check that the project was created
        assertEq(box.getProjectCount(), 1, "Project should be created");
        
        // Check that treasury was reduced
        assertEq(box.getTreasuryBalance(), treasuryAmount - projectFunding, "Treasury should be reduced");
    }
} 