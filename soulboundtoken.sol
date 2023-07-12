// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC5192.sol";

// @title A contract for mint an SBT
// @author MaxVast
// @dev Implementation Openzeppelin Ownable, Strings, ERC721, ERC721Enumerable and interface IERC5192
contract SoulboundToken is ERC721, ERC721Enumerable, Ownable {
    // Mapping from address to claim token
    mapping(address => bool) public claimedTokens;
    // Mapping from Token ID to address
    mapping(uint256 => address) public balanceOf;
    // Mapping from token ID to locked status
    mapping(uint256 => bool) _locked;

    //base URI of the NFTs
    string public baseURI;

    /// @notice Emitted when the token is claim.
    /// @dev If a token is claimed, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event TokenClaimed(address indexed user, uint256 tokenId);

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool) {
        require(balanceOf[tokenId] != address(0));
        return _locked[tokenId];
    }

    constructor(string memory baseURI_) ERC721("room lab SBT", "RLAB-SBT") {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Get the token URI of an SBT by his ID
    /// @param _tokenId The ID of the SBT you want to have the URI
    function tokenURI(uint _tokenId) public view virtual override(ERC721) returns(string memory) {
        require(_exists(_tokenId), "SBT NOT MINTED");

        return string(baseURI);
    }

    /// @notice Allows you to claim an SBT token and send it to the address 
    /// @dev must check that the user does not possess the token, 
    /// this function should mark the token at the sender address, send it and lock it, and emit the events
    function claimToken() external {
        require(!claimedTokens[msg.sender], "Token already claimed");

        // Marks token as claimed
        claimedTokens[msg.sender] = true;

        // Generate token internal
        uint256 tokenId = generateTokenId(msg.sender);
        _safeMint(msg.sender, tokenId);

        // Marks token Id requested from wallet
        balanceOf[tokenId] = msg.sender;

        // Marks token as blocked
        _locked[tokenId] = true;
        
        // Emits an event to notify that the token has been blocked
        emit Locked(tokenId);
        
        // Emits an event to notify the token claim
        emit TokenClaimed(msg.sender, tokenId);
    }

    /// @notice Creates a unique identifier from the user's address
    /// @dev must create a unique identifier for the SBT with the user's address
    /// @param user address wallet
    function generateTokenId(address user) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user)));
    }

    /// @notice Allows you to revoke a wallet's SBT 
    /// @dev Must check that the token ID of the SBT belongs to a wallet, 
    /// must remove the SBT from the mapping, must burn the SBT
    /// @param from address user, tokenId The identifier for an SBT.
    function recoverTokens(address from, uint256 tokenId) external onlyOwner {
        require(balanceOf[tokenId] == from, "The wallet doesn't hold this token");
        delete(balanceOf[tokenId]);
        _burn(tokenId);
    }

    /// @notice Burn your SBT
    /// @dev Must check that the SBT token ID belongs to the sender, Must burn the SBT
    /// @param tokenId The identifier for an SBT.
    function burn(uint256 tokenId) public {
        require(balanceOf[tokenId] == msg.sender, "The wallet doesn't hold this token");
        _burn(tokenId);
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(balanceOf[tokenId] == msg.sender, "You don't have this token");
        _;
    }

    modifier IsTransferAllowed(uint256 tokenId) {
        require(!_locked[tokenId]);
        _;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(IERC721, ERC721) returns (bool) {
         return false; // Disable global approval for all transfers
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }
}