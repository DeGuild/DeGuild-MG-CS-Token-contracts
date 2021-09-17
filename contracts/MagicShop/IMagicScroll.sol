// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagicScroll {

    event StateChanged(uint8 state);

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev When there is a problem, cancel this item.
     */
    function forceCancel(uint256 id) external;

    /**
     * @dev When user wants to take a test, consume this item.
     */
    function consume(uint256 id) external;

    /**
     * @dev When user want to get a certificate, burn this item.
     */
    function burn(uint256 id) external;

    function buyScroll(address buyer) external returns(uint256);

}