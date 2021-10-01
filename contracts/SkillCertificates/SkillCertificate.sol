// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISkillCertificate.sol";
import "contracts/MagicShop/IMagicScrolls.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SkillCertificate is Context, Ownable, ISkillCertificate {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the certificate existed
     * We need to know exactly what happened to the certificate
     * so we keep track of those certificates here.
     */
    mapping(uint256 => address) private _owners;
    mapping(address => bool) private _certified;

    /**
     * @dev Store the addresses of the shop.
     */
    address private _addressShop;

    string private _name;
    string private _symbol;
    string private _baseURIscroll;

    /**
     * @dev Store the type that this certificate manager accept.
     */
    uint256 private _scrollType;

    /**
     * @dev Store the ID of certificates
     */
    Counters.Counter private tracker = Counters.Counter(0);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressShop_,
        uint256 scrollType_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURIscroll = baseURI_;
        _addressShop = addressShop_;
        _scrollType = scrollType_;
    }

    /**
     * @dev See {ISkillCertificate-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {ISkillCertificate-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ISkillCertificate-shop}.
     */
    function shop() public view virtual override returns (address) {
        return _addressShop;
    }

    /**
     * @dev See {ISkillCertificate-typeAccepted}.
     */
    function typeAccepted() external view virtual override returns (uint256) {
        return _scrollType;
    }

    /**
     * @dev See {ISkillCertificate-tokenURI}.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenURI()
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _baseURI();
    }

    /**
     * @dev See {ISkillCertificate-ownerOf}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[id];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {ISkillCertificate-verify}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function verify(address student)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _certified[student];
    }

    /**
     * @dev See {ISkillCertificate-forceBurn}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceBurn(uint256 id)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _burn(id);
        return true;
    }

    /**
     * @dev See {ISkillCertificate-mint}.
     *
     * Requirements:
     *
     * - `to` must the owner of `scrollOwnedID`.
     * - `scrollOwnedID` must be burned.
     */
    function mint(address to, uint256 scrollOwnedID)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _mint(to, scrollOwnedID);
        return true;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }

    function _mint(address to, uint256 scrollOwnedID)
        internal
        virtual
        onlyOwner
    {
        require(
            IMagicScrolls(_addressShop).ownerOf(scrollOwnedID) == to,
            "Please burn the scroll owned by this address!"
        );
        require(
            IMagicScrolls(_addressShop).burn(scrollOwnedID),
            "Cannot burn the scroll!"
        );

        _owners[tracker.current()] = to;
        emit CertificateMinted(to, tracker.current());
        tracker.increment();
        _certified[to] = true;
    }

    function _burn(uint256 tokenId) internal virtual onlyOwner {
        require(_exists(tokenId), "Nonexistent token");
        emit CertificateBurned(_owners[tokenId], tokenId);
        _certified[_owners[tokenId]] = false;
        _owners[tokenId] = address(0);
    }
}
