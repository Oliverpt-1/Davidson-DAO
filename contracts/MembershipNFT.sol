// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DavidsonDAO Membership NFT
 * @dev NFT representing membership in the Davidson Blockchain Club DAO
 * Only verified members can receive these NFTs
 */
contract MembershipNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    // Token ID counter
    uint256 private _nextTokenId;
    
    // Mapping to track if an address has been verified
    mapping(address => bool) public isVerified;
    
    // Mapping to track if an address has a membership NFT
    mapping(address => bool) public hasMembership;
    
    // Base URI for token metadata
    string private _baseTokenURI;
    
    // Events
    event MemberVerified(address indexed member);
    event MembershipIssued(address indexed member, uint256 tokenId);
    event MembershipRevoked(address indexed member, uint256 tokenId);
    
    /**
     * @dev Constructor
     * @param initialOwner The initial owner of the contract (should be the DAO)
     * @param baseTokenURI The base URI for token metadata
     */
    constructor(address initialOwner, string memory baseTokenURI) 
        ERC721("Davidson DAO Membership", "DDAO") 
        Ownable(initialOwner) 
    {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Verify a member's eligibility for membership
     * @param member The address of the member to verify
     */
    function verifyMember(address member) external onlyOwner {
        require(!isVerified[member], "Member already verified");
        
        isVerified[member] = true;
        emit MemberVerified(member);
    }
    
    /**
     * @dev Batch verify multiple members
     * @param members Array of member addresses to verify
     */
    function batchVerifyMembers(address[] calldata members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            if (!isVerified[members[i]]) {
                isVerified[members[i]] = true;
                emit MemberVerified(members[i]);
            }
        }
    }
    
    /**
     * @dev Issue a membership NFT to a verified member
     * @param to The address of the verified member
     * @param tokenURI The URI for the token metadata
     */
    function issueMembership(address to, string memory tokenURI) external onlyOwner {
        require(isVerified[to], "Member not verified");
        require(!hasMembership[to], "Member already has membership NFT");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        hasMembership[to] = true;
        emit MembershipIssued(to, tokenId);
    }
    
    /**
     * @dev Allow a verified member to claim their membership NFT
     * @param tokenURI The URI for the token metadata
     */
    function claimMembership(string memory tokenURI) external {
        require(isVerified[msg.sender], "You are not verified");
        require(!hasMembership[msg.sender], "You already have a membership NFT");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        hasMembership[msg.sender] = true;
        emit MembershipIssued(msg.sender, tokenId);
    }
    
    /**
     * @dev Revoke a membership NFT
     * @param tokenId The ID of the token to revoke
     */
    function revokeMembership(uint256 tokenId) external onlyOwner {
        address owner = ownerOf(tokenId);
        
        _burn(tokenId);
        hasMembership[owner] = false;
        
        emit MembershipRevoked(owner, tokenId);
    }
    
    /**
     * @dev Set the base URI for token metadata
     * @param baseTokenURI The new base URI
     */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Get the total number of members
     * @return The total number of membership NFTs
     */
    function getMemberCount() external view returns (uint256) {
        return _nextTokenId;
    }
    
    /**
     * @dev Check if an address is a member
     * @param member The address to check
     * @return Whether the address has a membership NFT
     */
    function isMember(address member) external view returns (bool) {
        return hasMembership[member];
    }
    
    // The following functions are overrides required by Solidity
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
} 