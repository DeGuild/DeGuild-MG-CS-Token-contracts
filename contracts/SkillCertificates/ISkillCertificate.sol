// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISkillCertificate {
    /**
     * NFT style interface, but it does not simple transfer like other ERC721 and ERC1155
     * It requires DGC to work around with. Basically, we try to make a shop out of it!
     */

    event StateChanged(uint256 scrollId, uint8 scrollState);
    event CertificateMinted(
        uint256 scrollId);

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
    function forceBurn(uint256 id) external;
    
    /**
     * @dev When user want to get a certificate, burn this item.
     */
    function burn(uint256 id) external;

    function verify(address student)
        external
        returns (bool);

}