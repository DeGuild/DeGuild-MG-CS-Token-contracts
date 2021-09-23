// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISkillCertificate {
    /**
     * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
     * It requires MagicScrolls to work around with. Basically, we try to make a certificate out of it!
     */

    event CertificateMinted(address student, uint256 scrollId);

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

    function typeAccepted() external view returns (uint256);

    /**
     * @dev Returns the shop symbol.
     */
    function symbol() external view returns (string memory);

    function shop() external view returns (address);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev When there is a problem, cancel this item.
     */
    function forceBurn(uint256 id) external;

    /**
     * @dev When user want to get a certificate, mint this item and burn a scroll.
     */
    function mint(address to, uint256 scrollOwnedID) external returns (bool);

    /**
     * @dev returns the validity of the certificate of student.
     */
    function verify(address student) external view returns (bool);
}
