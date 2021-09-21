// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagicScrolls {
    /**
     * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
     * It requires DGC to work around with. Basically, we try to make a shop out of it!
     */

    event StateChanged(uint256 scrollId, uint8 scrollState);
    event ScrollBought(
        uint256 scrollId,
        uint256 scrollType
    );

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfAll(address account)
        external
        view
        returns (uint256[] memory);

    function balanceUserOwned(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 id) external view returns (address);

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

    function buyScroll(address buyer, uint256 scroll)
        external
        returns (uint256);

    function addScroll(
        uint256 _scrollID,
        address _prerequisite,
        bool _lessonIncluded,
        bool hasPrerequisite,
        uint256 _price
    ) external returns (uint256);
}
