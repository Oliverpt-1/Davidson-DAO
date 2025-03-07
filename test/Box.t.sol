// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Box.sol";

contract BoxTest is Test {
    Box public box;
    address public owner = address(1);
    address public nonOwner = address(2);
    
    function setUp() public {
        box = new Box(owner);
    }
    
    function testOwnership() public {
        assertEq(box.owner(), owner, "Owner should be set correctly");
        
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        box.updateTreasury(100);
    }
    
    function testTreasuryManagement() public {
        vm.startPrank(owner);
        
        // Update treasury
        box.updateTreasury(1000);
        assertEq(box.getTreasuryBalance(), 1000, "Treasury balance should be updated");
        
        // Update treasury again
        box.updateTreasury(2000);
        assertEq(box.getTreasuryBalance(), 2000, "Treasury balance should be updated again");
        
        vm.stopPrank();
    }
    
    function testOfficerManagement() public {
        vm.startPrank(owner);
        
        // Elect an officer
        string memory role = "President";
        uint256 termLength = 365 days;
        box.electOfficer(nonOwner, role, termLength);
        
        // Check officer count
        assertEq(box.getOfficerCount(), 1, "Officer count should be 1");
        
        // Get officer details
        (address officerAddress, string memory officerRole, uint256 electedTimestamp, uint256 termEndTimestamp) = box.officers(0);
        
        assertEq(officerAddress, nonOwner, "Officer address should match");
        assertEq(officerRole, role, "Officer role should match");
        assertTrue(termEndTimestamp > electedTimestamp, "Term end should be after elected timestamp");
        assertEq(termEndTimestamp - electedTimestamp, termLength, "Term length should match");
        
        vm.stopPrank();
    }
    
    function testProjectManagement() public {
        vm.startPrank(owner);
        
        // Update treasury first
        box.updateTreasury(1000);
        
        // Create a project
        string memory name = "Blockchain Workshop";
        string memory description = "Weekly workshops on blockchain";
        uint256 funding = 500;
        
        box.createProject(name, description, funding);
        
        // Check project count
        assertEq(box.getProjectCount(), 1, "Project count should be 1");
        
        // Check treasury was reduced
        assertEq(box.getTreasuryBalance(), 500, "Treasury should be reduced by project funding");
        
        // Get project details
        (string memory projectName, string memory projectDesc, uint256 projectFunding, bool isActive) = box.projects(0);
        
        assertEq(projectName, name, "Project name should match");
        assertEq(projectDesc, description, "Project description should match");
        assertEq(projectFunding, funding, "Project funding should match");
        assertTrue(isActive, "Project should be active");
        
        // Update project
        box.updateProject(0, false, 100);
        
        // Check project was updated
        (,,uint256 newFunding, bool newIsActive) = box.projects(0);
        assertEq(newFunding, 600, "Project funding should be updated");
        assertFalse(newIsActive, "Project should be inactive");
        
        // Check treasury was reduced again
        assertEq(box.getTreasuryBalance(), 400, "Treasury should be reduced by additional funding");
        
        vm.stopPrank();
    }
    
    function testPartnershipManagement() public {
        vm.startPrank(owner);
        
        // Create a partnership
        string memory partnerName = "Local University";
        string memory description = "Collaboration on blockchain education";
        uint256 duration = 180 days;
        
        box.createPartnership(partnerName, description, duration);
        
        // Check partnership count
        assertEq(box.getPartnershipCount(), 1, "Partnership count should be 1");
        
        // Get partnership details
        (string memory pName, string memory pDesc, uint256 startDate, uint256 endDate, bool isActive) = box.partnerships(0);
        
        assertEq(pName, partnerName, "Partner name should match");
        assertEq(pDesc, description, "Partnership description should match");
        assertEq(endDate - startDate, duration, "Partnership duration should match");
        assertTrue(isActive, "Partnership should be active");
        
        // Update partnership
        box.updatePartnership(0, false);
        
        // Check partnership was updated
        (,,,, bool newIsActive) = box.partnerships(0);
        assertFalse(newIsActive, "Partnership should be inactive");
        
        vm.stopPrank();
    }
    
    function testInsufficientFunds() public {
        vm.startPrank(owner);
        
        // Update treasury
        box.updateTreasury(100);
        
        // Try to create a project with more funding than available
        vm.expectRevert("Insufficient funds in treasury");
        box.createProject("Test Project", "Test Description", 200);
        
        vm.stopPrank();
    }
} 