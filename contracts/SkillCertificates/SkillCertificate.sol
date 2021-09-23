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
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    mapping(uint256 => address) _owners;
    mapping(address => bool) _certified;

    address _addressDGC;
    string _name;
    address _addressShop;
    string _symbol;
    string _baseURIscroll;
    uint256 _scrollType;
    Counters.Counter tracker = Counters.Counter(0);

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
     * @dev Returns the token collection name.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token collection name.
     */
    function typeAccepted() external view virtual override returns (uint256) {
        return _scrollType;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev See {IERC721-ownerOf}.
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
     * @dev When there is a problem, cancel this item.
     */
    function forceBurn(uint256 id) external virtual override onlyOwner {
        _burn(id);
    }

    /**
     * @dev When user want to get a certificate, burn this item.
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
     * @dev Returns the token collection symbol.
     */
    function shop() external view virtual override returns (address) {
        return _addressShop;
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
            IMagicScrolls(_addressShop).burn(scrollOwnedID),
            "Cannot burn the scroll!"
        );

        _owners[tracker.current()] = to;
        emit CertificateMinted(tracker.current());
        tracker.increment();
        _certified[to] = true;
    }

    function _burn(uint256 tokenId) internal virtual onlyOwner {
        _certified[_owners[tokenId]] = false;
        _owners[tokenId] = address(0);
    }
}
