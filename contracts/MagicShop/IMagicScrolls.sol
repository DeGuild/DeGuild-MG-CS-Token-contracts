// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
 * It requires DGC & SkillCertificate to work around with. Basically, we try to make a shop out of it!
 */
interface IMagicScrolls {

     /**
     * @dev From logging, we show that the minted scroll has changed its state
     */
    event StateChanged(uint256 scrollId, uint8 scrollState);

    /**
     * @dev From logging, we show that the a scroll of one type has been minted
     */
    event ScrollBought(
        uint256 scrollId,
        uint256 scrollType
    );

    /**
     * @dev From logging, we show that the a type of scroll has been added to the list
     */
    event ScrollAdded(
        uint256 scrollID,
        uint256 price,
        address prerequisite,
        address certificate,
        bool lessonIncluded,
        bool hasPrerequisite,
        bool available
    );

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id) external view returns (address);
    
    /**
     * @dev Returns the shop name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the shop symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    /**
     * @dev Returns the number of scroll types available to be bought
     */
    function numberOfScrollTypes() external view returns(uint256);

    /**
     * @dev Returns the balance that this account owned, according to type
     */
    function balanceOfAll(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the balance that this account owned, according to ownership of minted scrolls
     */
    function balanceUserOwned(address account)
        external
        view
        returns (uint256[] memory);

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

    /**
     * @dev When user want to get a scroll, transfer DGC to owner of the shop, returns the newest minted id.
     */
    function buyScroll(address buyer, uint256 scroll)
        external
        returns (uint256);

    /**
     * @dev When owner want to add a scroll, returns the newest scroll type id.
     */
    function addScroll(
        uint256 scrollID,
        address prerequisite,
        address certificate,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external returns (uint256);

    /**
     * @dev When owner want to seal a scroll, it will check for existence and seal them forever (not mintable anymore and cannot be used later on).
     */
    function sealScroll(uint256 scrollType) external;
}
