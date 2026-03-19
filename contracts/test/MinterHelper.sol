// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Test helper contract that simulates a smart contract wallet calling mint().
contract MinterHelper {
    function doMint(address badge) external payable {
        (bool success, bytes memory data) = badge.call{value: msg.value}(
            abi.encodeWithSignature("mint()")
        );
        if (!success) {
            // Bubble up the revert reason
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
            revert("MinterHelper: mint failed");
        }
    }

    // Required to receive ERC-721 tokens via safeMint
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Allow receiving native token (OKB)
    receive() external payable {}
}
