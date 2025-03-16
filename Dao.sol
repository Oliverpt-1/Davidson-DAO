// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./contracts/GovernanceToken.sol";
import "./contracts/Box.sol";
import "./contracts/MembershipNFT.sol";

/**
 * @title DavidsonDAO
 * @dev A simple DAO for the Davidson Blockchain Club
 * Allows token holders to create and vote on proposals
 * Requires membership NFT for governance participation
 */
contract DavidsonDAO {
    // The token used for voting
    GovernanceToken public token;
    
    // The contract controlled by the DAO
    Box public box;
    
    // The membership NFT contract
    MembershipNFT public membershipNFT;
    
    // Proposal struct
    struct Proposal {
        // The address of the proposer
        address proposer;
        
        // The title of the proposal
        string title;
        
        // The description of the proposal
        string description;
        
        // The target contract to call
        address target;
        
        // The function signature to call
        bytes callData;
        
        // The block number when voting ends
        uint256 votingEnds;
        
        // The number of votes for the proposal
        uint256 votesFor;
        
        // The number of votes against the proposal
        uint256 votesAgainst;
        
        // Whether the proposal has been executed
        bool executed;
        
        // Mapping of addresses to whether they have voted
        mapping(address => bool) hasVoted;
    }
    
    // Mapping of proposal IDs to proposals
    mapping(uint256 => Proposal) public proposals;
    
    // The total number of proposals
    uint256 public proposalCount;
    
    // The minimum number of tokens required to create a proposal (1% of total supply)
    uint256 public constant PROPOSAL_THRESHOLD = 10000 * 10**18 / 100;
    
    // The voting period in blocks (approximately 1 week with 12s blocks)
    uint256 public constant VOTING_PERIOD = 50400;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        string description,
        address target,
        bytes callData,
        uint256 votingEnds
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor,
        bool success
    );
    
    event MemberVerified(address indexed member);
    event MembershipIssued(address indexed member, uint256 tokenId);
    
    /**
     * @dev Constructor
     * @param _token The governance token
     */
    constructor(GovernanceToken _token) {
        token = _token;
        
        // Create a new Box contract owned by this DAO
        box = new Box(address(this));
        
        // Create a new MembershipNFT contract owned by this DAO
        membershipNFT = new MembershipNFT(address(this), "https://davidson-dao.com/api/metadata/");
    }
    
    /**
     * @dev Verify a member's eligibility for membership
     * @param _member The address of the member to verify
     */
    function verifyMember(address _member) external {
        // Only the DAO itself (via proposal execution) can verify members
        require(msg.sender == address(this), "DavidsonDAO: only DAO can verify members");
        
        membershipNFT.verifyMember(_member);
        emit MemberVerified(_member);
    }
    
    /**
     * @dev Batch verify multiple members
     * @param _members Array of member addresses to verify
     */
    function batchVerifyMembers(address[] calldata _members) external {
        // Only the DAO itself (via proposal execution) can verify members
        require(msg.sender == address(this), "DavidsonDAO: only DAO can verify members");
        
        membershipNFT.batchVerifyMembers(_members);
        
        for (uint256 i = 0; i < _members.length; i++) {
            emit MemberVerified(_members[i]);
        }
    }
    
    /**
     * @dev Issue a membership NFT to a verified member
     * @param _to The address of the verified member
     * @param _tokenURI The URI for the token metadata
     */
    function issueMembership(address _to, string memory _tokenURI) external {
        // Only the DAO itself (via proposal execution) can issue memberships
        require(msg.sender == address(this), "DavidsonDAO: only DAO can issue memberships");
        
        membershipNFT.issueMembership(_to, _tokenURI);
        emit MembershipIssued(_to, membershipNFT.getMemberCount() - 1);
    }
    
    /**
     * @dev Create a new proposal
     * @param _title The title of the proposal
     * @param _description The description of the proposal
     * @param _target The target contract to call
     * @param _callData The function call data
     * @return The ID of the new proposal
     */
    function propose(
        string memory _title,
        string memory _description,
        address _target,
        bytes memory _callData
    ) public returns (uint256) {
        // Check that the proposer has a membership NFT
        require(
            membershipNFT.isMember(msg.sender),
            "DavidsonDAO: proposer must be a member"
        );
        
        // Check that the proposer has enough tokens
        require(
            token.getPastVotes(msg.sender, block.number - 1) >= PROPOSAL_THRESHOLD,
            "DavidsonDAO: proposer votes below threshold"
        );
        
        // Create the proposal
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.target = _target;
        proposal.callData = _callData;
        proposal.votingEnds = block.number + VOTING_PERIOD;
        proposal.executed = false;
        
        // Emit event
        emit ProposalCreated(
            proposalId,
            msg.sender,
            _title,
            _description,
            _target,
            _callData,
            proposal.votingEnds
        );
        
        return proposalId;
    }
    
    /**
     * @dev Cast a vote on a proposal
     * @param _proposalId The ID of the proposal
     * @param _support Whether to support the proposal
     */
    function castVote(uint256 _proposalId, bool _support) public {
        // Check that the voter has a membership NFT
        require(
            membershipNFT.isMember(msg.sender),
            "DavidsonDAO: voter must be a member"
        );
        
        Proposal storage proposal = proposals[_proposalId];
        
        // Check that the proposal exists and voting is still open
        require(proposal.proposer != address(0), "DavidsonDAO: proposal doesn't exist");
        require(block.number <= proposal.votingEnds, "DavidsonDAO: voting closed");
        require(!proposal.hasVoted[msg.sender], "DavidsonDAO: already voted");
        
        // Mark the sender as having voted
        proposal.hasVoted[msg.sender] = true;
        
        // Get the voting weight - use current block number instead of proposal start
        uint256 weight = token.getPastVotes(msg.sender, block.number - 1);
        
        // Update the vote count
        if (_support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        
        // Emit event
        emit VoteCast(_proposalId, msg.sender, _support, weight);
    }
    
    /**
     * @dev Execute a successful proposal
     * @param _proposalId The ID of the proposal
     */
    function execute(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        
        // Check that the proposal exists, voting is closed, and it hasn't been executed
        require(proposal.proposer != address(0), "DavidsonDAO: proposal doesn't exist");
        require(block.number > proposal.votingEnds, "DavidsonDAO: voting still open");
        require(!proposal.executed, "DavidsonDAO: already executed");
        
        // Check that the proposal passed
        require(proposal.votesFor > proposal.votesAgainst, "DavidsonDAO: proposal failed");
        
        // Mark the proposal as executed
        proposal.executed = true;
        
        // Execute the proposal
        (bool success, ) = proposal.target.call(proposal.callData);
        
        // Emit event
        emit ProposalExecuted(_proposalId, msg.sender, success);
    }
    
    /**
     * @dev Get the state of a proposal
     * @param _proposalId The ID of the proposal
     * @return 0: Pending, 1: Active, 2: Defeated, 3: Succeeded, 4: Executed
     */
    function state(uint256 _proposalId) public view returns (uint8) {
        Proposal storage proposal = proposals[_proposalId];
        
        // Check that the proposal exists
        require(proposal.proposer != address(0), "DavidsonDAO: proposal doesn't exist");
        
        // If the proposal has been executed, return Executed
        if (proposal.executed) {
            return 4; // Executed
        }
        
        // If voting is still open, return Active
        if (block.number <= proposal.votingEnds) {
            return 1; // Active
        }
        
        // If the proposal passed, return Succeeded
        if (proposal.votesFor > proposal.votesAgainst) {
            return 3; // Succeeded
        }
        
        // Otherwise, return Defeated
        return 2; // Defeated
    }
    
    /**
     * @dev Get the details of a proposal
     * @param _proposalId The ID of the proposal
     * @return proposer The address of the proposer
     * @return title The title of the proposal
     * @return description The description of the proposal
     * @return target The target contract to call
     * @return callData The function call data
     * @return votingEnds The block number when voting ends
     * @return votesFor The number of votes for the proposal
     * @return votesAgainst The number of votes against the proposal
     * @return executed Whether the proposal has been executed
     */
    function getProposal(uint256 _proposalId) public view returns (
        address proposer,
        string memory title,
        string memory description,
        address target,
        bytes memory callData,
        uint256 votingEnds,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.votingEnds,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }
    
    /**
     * @dev Check if an address has voted on a proposal
     * @param _proposalId The ID of the proposal
     * @param _voter The address to check
     * @return Whether the address has voted
     */
    function hasVoted(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }
}
