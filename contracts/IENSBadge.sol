// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IENSBadge - Interface for Agentic Wallet ENS Badge
/// @notice Use this interface to detect and interact with ENS Badge contracts via ERC-165.
/// @dev AI agents can call supportsInterface(type(IENSBadge).interfaceId) to identify ENS Badge contracts.
interface IENSBadge {
    /// @notice Mint a new ENS Badge for your Agentic Wallet.
    /// @dev Requires 0.1 OKB payment. Only callable by smart contract wallets (not EOAs).
    /// Each address can only mint one badge. Badge number auto-increments from 1.
    function mint() external payable;

    /// @notice Query badge information for a given wallet address.
    /// @dev Returns whether the address has a badge, its number, and total minted count.
    /// @param wallet The address to query.
    /// @return hasBadge True if the address owns a badge.
    /// @return badgeNumber The badge number (0 if no badge).
    /// @return totalMinted Total number of badges minted so far.
    function getBadgeInfo(address wallet) external view returns (bool hasBadge, uint256 badgeNumber, uint256 totalMinted);

    /// @notice Get the badge number for a given token ID.
    /// @param tokenId The NFT token ID.
    /// @return The badge number (equals tokenId).
    function getBadgeNumber(uint256 tokenId) external pure returns (uint256);

    /// @notice Get the total number of badges minted.
    /// @return The total count of minted badges.
    function totalMinted() external view returns (uint256);

    /// @notice The price to mint one badge, in wei (0.1 OKB = 100000000000000000 wei).
    function MINT_PRICE() external view returns (uint256);

    /// @notice Emitted when a new badge is minted.
    /// @param wallet The address that received the badge.
    /// @param badgeNumber The sequential badge number assigned.
    event BadgeMinted(address indexed wallet, uint256 indexed badgeNumber);
}
