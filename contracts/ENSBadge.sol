// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./IENSBadge.sol";

/// @title Agentic Wallet ENS Badge
/// @notice AGENT PROTOCOL: This contract issues sequential identity badges for AI agents
/// operating Agentic Wallets on X Layer (Chain ID 196). Each badge is a unique ERC-721 NFT
/// with an auto-incrementing number. To mint: call mint() with 0.1 OKB from a smart contract
/// wallet. To verify an agent: call getBadgeInfo(address). One badge per address.
/// @dev Implements ERC-721 with fully on-chain SVG metadata and agent-readable descriptions.
contract ENSBadge is ERC721, Ownable, IENSBadge {
    using Strings for uint256;
    using Strings for address;

    uint256 private _nextBadgeId = 2; // Starts at 2 because #1 is pre-minted in constructor
    uint256 public constant MINT_PRICE = 0.1 ether; // 0.1 OKB

    /// @notice Maps address to whether it has already minted a badge.
    mapping(address => bool) public hasMinted;

    /// @notice Maps address to its badge token ID (0 if none).
    mapping(address => uint256) public badgeOf;

    /// @notice Creates the ENS Badge contract and pre-mints Badge #1 to the owner.
    /// @param initialOwner The developer address that receives mint fees and Badge #1.
    constructor(address initialOwner) ERC721("Agentic Wallet ENS Badge", "ENSBADGE") Ownable(initialOwner) {
        // Pre-mint Badge #1 to owner (bypasses the smart-contract-only check)
        _safeMint(initialOwner, 1);
        hasMinted[initialOwner] = true;
        badgeOf[initialOwner] = 1;
        emit BadgeMinted(initialOwner, 1);
    }

    /// @notice Mint a new ENS Badge for your Agentic Wallet.
    /// @dev Requires 0.1 OKB. Only callable by smart contract wallets (msg.sender != tx.origin).
    /// Each address can only mint one badge. Mint fee is forwarded to the contract owner.
    function mint() external payable override {
        require(msg.sender != tx.origin, "ENSBadge: only smart contract wallets allowed");
        require(!hasMinted[msg.sender], "ENSBadge: already minted");
        require(msg.value >= MINT_PRICE, "ENSBadge: insufficient payment (need 0.1 OKB)");

        uint256 badgeId = _nextBadgeId;
        _nextBadgeId++;

        hasMinted[msg.sender] = true;
        badgeOf[msg.sender] = badgeId;

        _safeMint(msg.sender, badgeId);

        // Forward mint fee to owner
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "ENSBadge: fee transfer failed");

        emit BadgeMinted(msg.sender, badgeId);
    }

    /// @notice Query badge information for a given wallet address.
    /// @param wallet The address to query.
    /// @return hasBadge True if the address owns a badge.
    /// @return badgeNumber The badge number (0 if no badge).
    /// @return _totalMinted Total number of badges minted so far.
    function getBadgeInfo(address wallet) external view override returns (
        bool hasBadge,
        uint256 badgeNumber,
        uint256 _totalMinted
    ) {
        hasBadge = hasMinted[wallet];
        badgeNumber = badgeOf[wallet];
        _totalMinted = _nextBadgeId - 1;
    }

    /// @notice Get the badge number for a given token ID.
    /// @param tokenId The NFT token ID.
    /// @return The badge number (equals tokenId).
    function getBadgeNumber(uint256 tokenId) external pure override returns (uint256) {
        return tokenId;
    }

    /// @notice Get the total number of badges minted.
    /// @return The total count of minted badges.
    function totalMinted() external view override returns (uint256) {
        return _nextBadgeId - 1;
    }

    /// @notice Returns fully on-chain metadata with agent-readable description and SVG image.
    /// @param tokenId The token ID to query.
    /// @return A data URI containing Base64-encoded JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        address tokenOwner = ownerOf(tokenId);
        string memory badgeNum = tokenId.toString();
        string memory ownerAddr = Strings.toHexString(tokenOwner);

        string memory json = string.concat(
            _buildJsonPart1(badgeNum, ownerAddr),
            _buildJsonPart2(badgeNum, ownerAddr, _shortenAddress(tokenOwner))
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /// @notice Returns collection-level metadata with agent protocol description.
    /// @return A data URI containing Base64-encoded JSON collection metadata.
    function contractURI() external view returns (string memory) {
        string memory contractAddr = Strings.toHexString(address(this));

        string memory json = string.concat(
            '{"name":"Agentic Wallet ENS Badges","description":"AGENT PROTOCOL: This collection contains identity badges for AI agents operating Agentic Wallets on X Layer (Chain ID 196). Each badge has a unique sequential number. To mint: call mint() with 0.1 OKB from a smart contract wallet. To verify an agent: call getBadgeInfo(address). Contract address: ', contractAddr,
            '. Implements IENSBadge interface detectable via ERC-165.","external_link":"https://www.oklink.com/xlayer"}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /// @notice ERC-165 interface detection. Returns true for ERC-721, IENSBadge, and ERC-165.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IENSBadge).interfaceId || super.supportsInterface(interfaceId);
    }

    // ========== Internal Helpers ==========

    /// @dev Builds the first part of the tokenURI JSON (name, description, image).
    function _buildJsonPart1(string memory badgeNum, string memory ownerAddr) internal view returns (string memory) {
        string memory contractAddr = Strings.toHexString(address(this));
        return string.concat(
            '{"name":"Agentic Wallet ENS Badge #', badgeNum,
            '","description":"AGENT INSTRUCTIONS: This is an ENS Identity Badge for Agentic Wallets on X Layer (Chain ID 196). Badge #', badgeNum,
            ' is currently held by address ', ownerAddr,
            '. This ERC-721 NFT serves as a unique, transferable identity credential for AI agents. The badge number is a sequential identifier assigned at mint time. To verify an agent, call getBadgeInfo(address) on contract ', contractAddr,
            ' which returns (hasBadge, badgeNumber, totalMinted)."'
        );
    }

    /// @dev Builds the second part of the tokenURI JSON (image, attributes, agent_info).
    function _buildJsonPart2(string memory badgeNum, string memory ownerAddr, string memory shortAddr) internal view returns (string memory) {
        string memory contractAddr = Strings.toHexString(address(this));
        string memory svg = _generateSVG(badgeNum, shortAddr);
        return string.concat(
            ',"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
            '","attributes":[{"trait_type":"Badge Number","value":', badgeNum,
            ',"display_type":"number"},{"trait_type":"Chain","value":"X Layer"},{"trait_type":"Type","value":"Identity Badge"},{"trait_type":"Owner","value":"', ownerAddr,
            '"}],"agent_info":{"contract_type":"ENSBadge","purpose":"Agentic Wallet Identity Badge","is_transferable":true,"mint_price_okb":"0.1","chain_id":196,"rpc":"https://rpc.xlayer.tech","contract_address":"', contractAddr,
            '","how_to_verify":"Call getBadgeInfo(address)","how_to_mint":"Call mint() with 0.1 OKB from a smart contract wallet."}}'
        );
    }

    /// @dev Generates the on-chain SVG badge image (hacker style: black/white with green accent).
    function _generateSVG(string memory badgeNum, string memory shortAddr) internal pure returns (string memory) {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">'
            '<rect width="400" height="400" fill="#000"/>'
            '<rect x="10" y="10" width="380" height="380" fill="none" stroke="#333" stroke-width="1"/>'
            '<text x="200" y="55" font-family="monospace" font-size="11" fill="#888" text-anchor="middle">&gt;_ ENS BADGE</text>'
            '<text x="200" y="110" font-family="monospace" font-size="11" fill="#aaa" text-anchor="middle">Agentic Wallet</text>',
            '<text x="200" y="220" font-family="monospace" font-size="90" fill="#fff" text-anchor="middle" font-weight="bold">#', badgeNum, '</text>',
            '<text x="200" y="320" font-family="monospace" font-size="10" fill="#0f0" text-anchor="middle" opacity="0.6">X Layer | Chain ID 196</text>'
            '<text x="200" y="350" font-family="monospace" font-size="10" fill="#555" text-anchor="middle">', shortAddr, '</text>'
            '</svg>'
        );
    }

    /// @dev Shortens an address to 0xABCD...EFGH format.
    function _shortenAddress(address addr) internal pure returns (string memory) {
        string memory full = Strings.toHexString(addr);
        bytes memory fullBytes = bytes(full);
        // "0x" + first 4 hex + "..." + last 4 hex
        bytes memory result = new bytes(13);
        // Copy "0x" + 4 chars = 6 bytes
        for (uint256 i = 0; i < 6; i++) {
            result[i] = fullBytes[i];
        }
        // "..."
        result[6] = ".";
        result[7] = ".";
        result[8] = ".";
        // Last 4 hex chars
        uint256 len = fullBytes.length;
        for (uint256 i = 0; i < 4; i++) {
            result[9 + i] = fullBytes[len - 4 + i];
        }
        return string(result);
    }
}
