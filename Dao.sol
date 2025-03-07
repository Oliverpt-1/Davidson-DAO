// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./contracts/GovernanceToken.sol";
import "./contracts/Governance Standard/GovernorContract.sol";
import "./contracts/Governance Standard/Timelock.sol";
import "./contracts/Box.sol";

/**
 * @title DavidsonDAO
 * @dev Main contract for the Davidson DAO
 * This contract serves as a factory to deploy all the necessary contracts for the DAO
 */
contract DavidsonDAO {
    GovernanceToken public governanceToken;
    Timelock public timelock;
    GovernorContract public governor;
    Box public box;

    // DAO Parameters
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    uint256 public constant VOTING_DELAY = 1; // 1 block
    uint256 public constant VOTING_PERIOD = 50400; // ~1 week (assuming 12s blocks)
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of voters need to vote

    event DAODeployed(
        address governanceToken,
        address timelock,
        address governor,
        address box
    );

    constructor() {
        // Deploy Governance Token
        governanceToken = new GovernanceToken();
        
        // Deploy Timelock
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Allow anyone to execute
        timelock = new Timelock(MIN_DELAY, proposers, executors);
        
        // Deploy Governor
        governor = new GovernorContract(
            governanceToken,
            timelock,
            QUORUM_PERCENTAGE,
            VOTING_PERIOD,
            VOTING_DELAY
        );
        
        // Set up roles
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();
        
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Allow anyone to execute
        timelock.revokeRole(adminRole, msg.sender); // Revoke admin role from deployer
        
        // Deploy Box owned by the timelock
        box = new Box(address(timelock));
        
        emit DAODeployed(
            address(governanceToken),
            address(timelock),
            address(governor),
            address(box)
        );
    }
}
