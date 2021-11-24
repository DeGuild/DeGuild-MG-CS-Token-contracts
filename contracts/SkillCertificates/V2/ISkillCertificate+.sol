// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT style interface, but it does not simple transfer like other ERC1155
 * It requires MagicScrolls to work around with. Basically, we try to make a certificate out of it!
 */
interface ISkillCertificatePlus {
    /**
     * @dev Emitted when `scrollId` certificate is minted for `student`.
     */
    event CertificateMinted(address indexed student, uint256 scrollId, uint256 typeId);

    /**
     * @dev Emitted when `scrollId` certificate is burned for `student`.
     */
    event CertificateBurned(address indexed student, uint256 scrollId, uint256 typeId);

    /**
     * @dev Returns the certificate name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the certificate symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the associated shop address.
     */
    function shop() external view returns (address);

    function typesExisted() external view returns (uint256);

    /**
     * @dev Returns the type of scroll accepted from associated shop address.
     */
    function typeAccepted(uint256 typeId) external view returns (uint256);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 typeId) external view returns (string memory);

    /**
     * @dev Returns the owner of the `id` token.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOfType(uint256 tokenId, uint256 typeId)
        external
        view
        returns (address);

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
    function verify(address student, uint256 typeId)
        external
        view
        returns (bool);

    function addCertificate(uint256 scrollTypeId)
        external
        returns (bool);

    /**
     * @dev Burn `id` token to address(0) (Also, void the certification).
     *
     * Usage : Burn the certificate.
     * Emits a {CertificateBurned} event.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceBurn(uint256 id, uint256 typeId) external returns (bool);

    /**
     * @dev Mind a token to `to` (Also, give the certification and burn `scrollOwnedID` in the shop).
     *
     * Usage : Mint the certificate.
     * Emits a {CertificateMinted} event.
     *
     * Requirements:
     *
     * - `to` must the owner of `scrollOwnedID`.
     * - `scrollOwnedID` must be burned.
     */
    function mint(
        address to,
        uint256 scrollOwnedID,
        uint256 typeId
    ) external returns (bool);

    /**
     * @dev Mind a token to `to` (Also, give the certification and burn `scrollOwnedID` in the shop).
     *
     * Usage : Mint the certificate.
     * Emits a {CertificateMinted} event.
     *
     * Requirements:
     *
     * - `to` must the owner of `scrollOwnedID`.
     * - `scrollOwnedID` must be burned.
     */
    function batchMint(
        address[] memory to,
        uint256[] memory scrollOwnedID,
        uint256 typeId
    ) external returns (bool);
}
