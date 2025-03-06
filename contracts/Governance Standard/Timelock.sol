// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//Proposals do not go in effect right away. Gives holders time to get out
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    // minDelay: How long you have to wait before executing
    // proposers: List of addresses that can propose
    // executors: List of addresses that can execute
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}