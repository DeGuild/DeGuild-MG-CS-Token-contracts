// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not allow transfer like other ERC721 and ERC1155
 * It requires DGT & SkillCertificate to work around with. Basically, we try to make a shop out of it!
 * As the first version, here are the list of functions, events, and structs we used.
 */
interface IMagicScrollsPlus {
    /**
     * @dev This data type is used to store the data of a magic scroll.
     * scrollID         (uint256) is the unique type of that scroll.
     * price            (uint256) is the price of that scroll.
     * prerequisite     (address) is the address of the certificate manager (any address is fine, if it has no prerequisite).
     * state            (uint8)   is the state of the scroll (Consumed or cancelled or fresh).
     * lessonIncluded   (bool)    is the state telling that this scroll can be used for unlocking learning materials off-chain.
     * hasPrerequisite  (bool)    is the state telling that this scroll requires a certificate from the certificate manager given.
     * available        (bool)    is the state telling that this scroll is no longer purchasable
     *                            (only used to check the availability to mint various magic scroll types)
     */
    struct MagicScroll {
        uint256 scrollID;
        uint256 price;
        uint256 certificateId;
        address prerequisite;
        uint8 state;
        bool lessonIncluded;
        bool hasPrerequisite;
        bool available;
    }

    /**
     * @dev Emitted when `scrollId` make changes to its state, changing to `scrollState`.
     */
    event StateChanged(uint256 scrollId, uint8 scrollState);

    /**
     * @dev Emitted when `scrollId` is minted based from scroll of type `scrollType`.
     */
    event ScrollBought(uint256 scrollId, uint256 indexed scrollType, address buyer);

    /**
     * @dev Emitted when a new scroll is added, giving that scroll of type `scrollId` is ready to be minted.
     */
    event ScrollAdded(
        uint256 indexed scrollType
    );

    /**
     * @dev Emitted when `account` gained or lost permission to be a certificate manager.
     */
    event ApprovalForCM(address indexed account, bool status);

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
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token type.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenTypeURI(uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Returns the number of scroll types available to be bought
     */
    function numberOfScrollTypes() external view returns (uint256);

    /**
     * @dev Returns the acceptable token address.
     */
    function deguildCoin() external view returns (address);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id) external view returns (address);

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
     * @dev Returns the balance that `account` owned, according to types.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfAll(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the balance that `account` owned, according to ownership of
     * minted scrolls.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceUserOwned(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns true if `manager` is approved to burn tokens.
     */
    function isCertificateManager(address manager) external view returns (bool);

    /**
     * @dev Returns true if `scrollType` is purchasable for `buyer`.
     *      Each scroll has its own conditions to purchase.
     */
    function isPurchasableScroll(uint256 scrollType, address buyer)
        external
        view
        returns (bool);

    /**
     * @dev Returns the array of scroll types' ids that are available to be purchase.
     */
    function scrollTypes() external view returns (uint256[] memory);

    /**
     * @dev Returns the information of the token type of `typeId`.
     * [0] (uint256)    typeId
     * [1] (uint256)    price of this `typeId` type
     * [2] (address)    prerequisite of this `typeId` type
     * [3] (bool)       lessonIncluded of this `typeId` type
     * [4] (bool)       hasPrerequisite of this `typeId` type
     * [5] (bool)       available of this `typeId` type
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollTypeInfo(uint256 typeId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        );

    /**
     * @dev Returns the information of the token type of `tokenId`.
     * [0] (uint256)    tokenId
     * [1] (uint256)    scrollID of this `tokenId`.
     * [2] (uint256)    price of this `tokenId`.
     * [3] (address)    prerequisite of this `tokenId`.
     * [4] (bool)       lessonIncluded of this `tokenId`.
     * [5] (bool)       hasPrerequisite of this `tokenId`.
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollInfo(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        );

    /**
     * @dev Change `id` token state to 99 (Cancelled).
     *
     * Usage : Neutralize the scroll if something fishy occurred with the owner.
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceCancel(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 2 (Consumed).
     *
     * Usage : Unlock a key from certificate manager to take examination
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function consume(uint256 id) external returns (bool);

    /**
     * @dev Change `id` token state to 0 (Burned) and transfer ownership to address(0).
     *
     * Usage : Burn the token
     * Emits a {StateChanged} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - If the caller is not a certificate manager, then we reject the call.
     * - If the certificate manager do not accept this type of scroll, we also reject this call.
     * - If the scroll is not fresh, reject it.
     */
    function burn(uint256 id) external returns (bool);

    /**
     * @dev Mint a scroll of type `scroll`.
     *
     * Usage : Buy a magic scroll
     * Emits a {ScrollBought} event.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be able to transfer DGT properly and succesfully.
     */
    function buyScroll(uint256 scroll) external returns (bool);

    /**
     * @dev Mint a type scroll.
     *
     * Usage : Add a magic scroll
     * Emits a {ScrollAdded} event.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be the owner of the shop.
     */
    function addScroll(
        uint256 certificateId,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external returns (bool);

    /**
     * @dev Set `manager` to be a CertificateManager or not.
     *
     * Emits a {ApprovalForCM} event.
     *
     * Requirements:
     *
     * - The caller must be the owner of the shop.
     */
    function setCertificateManager(address manager, bool status)
        external
        returns (bool);

    /**
     * @dev When owner want to seal a scroll, it will check for existence and seal them forever (not mintable anymore and cannot be used later on).
     *
     * Requirements:
     *
     * - `scroll` type must exist.
     * - The caller must be the owner of the shop.
     */
    function sealScroll(uint256 scrollType) external returns (bool);
}
