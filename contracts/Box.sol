// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Box
 * @dev A contract that will be controlled by the DAO
 * This contract handles Davidson Blockchain Club's resources and operations
 */
contract Box is Ownable {
  uint256 private treasuryBalance;
  
  // Club structure
  struct ClubOfficer {
    address officerAddress;
    string role; // "President", "Vice President", "Treasurer", etc.
    uint256 electedTimestamp;
    uint256 termEndTimestamp;
  }
  
  struct Project {
    string name;
    string description;
    uint256 fundingAllocated;
    bool isActive;
  }
  
  struct Partnership {
    string partnerName;
    string description;
    uint256 startDate;
    uint256 endDate;
    bool isActive;
  }
  
  ClubOfficer[] public officers;
  Project[] public projects;
  Partnership[] public partnerships;
  
  // Events
  event TreasuryUpdated(uint256 newBalance);
  event OfficerElected(address indexed officer, string role);
  event ProjectCreated(string name, uint256 fundingAllocated);
  event ProjectUpdated(uint256 indexed projectId, bool isActive, uint256 fundingAllocated);
  event PartnershipFormed(string partnerName, uint256 startDate, uint256 endDate);
  event PartnershipUpdated(uint256 indexed partnershipId, bool isActive);

  constructor(address initialOwner) Ownable(initialOwner) {}

  // Treasury management
  function updateTreasury(uint256 newBalance) public onlyOwner {
    treasuryBalance = newBalance;
    emit TreasuryUpdated(newBalance);
  }
  
  function getTreasuryBalance() public view returns (uint256) {
    return treasuryBalance;
  }
  
  // Officer management
  function electOfficer(address officerAddress, string memory role, uint256 termLength) public onlyOwner {
    uint256 currentTime = block.timestamp;
    officers.push(ClubOfficer({
      officerAddress: officerAddress,
      role: role,
      electedTimestamp: currentTime,
      termEndTimestamp: currentTime + termLength
    }));
    emit OfficerElected(officerAddress, role);
  }
  
  // Project management
  function createProject(string memory name, string memory description, uint256 fundingAllocated) public onlyOwner {
    require(fundingAllocated <= treasuryBalance, "Insufficient funds in treasury");
    treasuryBalance -= fundingAllocated;
    
    projects.push(Project({
      name: name,
      description: description,
      fundingAllocated: fundingAllocated,
      isActive: true
    }));
    
    emit ProjectCreated(name, fundingAllocated);
  }
  
  function updateProject(uint256 projectId, bool isActive, uint256 additionalFunding) public onlyOwner {
    require(projectId < projects.length, "Project does not exist");
    require(additionalFunding <= treasuryBalance, "Insufficient funds in treasury");
    
    Project storage project = projects[projectId];
    project.isActive = isActive;
    
    if (additionalFunding > 0) {
      treasuryBalance -= additionalFunding;
      project.fundingAllocated += additionalFunding;
    }
    
    emit ProjectUpdated(projectId, isActive, project.fundingAllocated);
  }
  
  // Partnership management
  function createPartnership(string memory partnerName, string memory description, uint256 duration) public onlyOwner {
    uint256 currentTime = block.timestamp;
    partnerships.push(Partnership({
      partnerName: partnerName,
      description: description,
      startDate: currentTime,
      endDate: currentTime + duration,
      isActive: true
    }));
    
    emit PartnershipFormed(partnerName, currentTime, currentTime + duration);
  }
  
  function updatePartnership(uint256 partnershipId, bool isActive) public onlyOwner {
    require(partnershipId < partnerships.length, "Partnership does not exist");
    
    Partnership storage partnership = partnerships[partnershipId];
    partnership.isActive = isActive;
    
    emit PartnershipUpdated(partnershipId, isActive);
  }
  
  // Getters
  function getOfficerCount() public view returns (uint256) {
    return officers.length;
  }
  
  function getProjectCount() public view returns (uint256) {
    return projects.length;
  }
  
  function getPartnershipCount() public view returns (uint256) {
    return partnerships.length;
  }
}