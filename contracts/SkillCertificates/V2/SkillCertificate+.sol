// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISkillCertificate+.sol";
import "contracts/MagicShop/V2/IMagicScrolls+.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../Utils/EIP-55.sol";

contract SkillCertificatePlus is Context, Ownable, ISkillCertificatePlus {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;
    using ERC165Checker for address;

    /**
     * @dev Classic ERC1155 mapping, tracking down the certificate existed
     * We need to know exactly what happened to the certificate
     * so we keep track of those certificates here.
     */
    mapping(uint256 => mapping(uint256 => address)) private _owners;
    mapping(uint256 => mapping(address => bool)) private _certified;

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
    mapping(uint256 => uint256) private _scrollType;

    /**
     * @dev Store the ID of certificates
     */
    mapping(uint256 => Counters.Counter) private _trackers;
    Counters.Counter private _typeTracker = Counters.Counter(0);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressShop_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURIscroll = baseURI_;
        _addressShop = addressShop_;
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

    function typesExisted() public view virtual override returns (uint256) {
        return _typeTracker.current();
    }

    /**
     * @dev See {ISkillCertificate-typeAccepted}.
     */
    function typeAccepted(uint256 typeId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _scrollType[typeId];
    }

    /**
     * @dev See {ISkillCertificate-ownerOf}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function ownerOfType(uint256 tokenId, uint256 tokenType)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenType][tokenId];
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
    function verify(address student, uint256 typeId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _certified[typeId][student];
    }

    /**
     * @dev See {ISkillCertificate-tokenURI}.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
     */
    function tokenURI(uint256 typeId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        abi.encodePacked(
                            address(this).getChecksum(),
                            abi.encodePacked("/", typeId.toString())
                        )
                    )
                )
                : "";
    }

    function addCertificate(uint256 scrollTypeId)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _addCertificate(scrollTypeId);
        return true;
    }

    function _addCertificate(uint256 scrollTypeId) private {
        _scrollType[_typeTracker.current()] = scrollTypeId;
        _trackers[_typeTracker.current()] = Counters.Counter(0);
        _typeTracker.increment();
    }

    /**
     * @dev See {ISkillCertificate-forceBurn}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceBurn(uint256 id, uint256 typeId)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _burn(id, typeId);
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
    function mint(
        address to,
        uint256 scrollOwnedID,
        uint256 typeId
    ) external virtual override onlyOwner returns (bool) {
        _mint(to, scrollOwnedID, typeId);
        return true;
    }

    function _exists(uint256 tokenId, uint256 typeId)
        private
        view
        returns (bool)
    {
        return _owners[typeId][tokenId] != address(0);
    }

    function _existsType(uint256 typeId) private view returns (bool) {
        return _typeTracker.current() > typeId;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() private view returns (string memory) {
        return _baseURIscroll;
    }

    function _mint(
        address to,
        uint256 scrollOwnedID,
        uint256 typeId
    ) private {
        require(_existsType(typeId), "You cannot mint to non-existing type");
        require(
            _addressShop.supportsInterface(type(IMagicScrollsPlus).interfaceId),
            "Address is not supported"
        );
        require(
            IMagicScrollsPlus(_addressShop).ownerOf(scrollOwnedID) == to,
            "Please burn the scroll owned by this address!"
        );
        (, uint256 scrollType, , , , ) = IMagicScrollsPlus(_addressShop)
            .scrollInfo(scrollOwnedID);
        require(
            scrollType == typeId,
            "You cannot burn this type of scroll for this type of certificate!"
        );
        require(
            IMagicScrollsPlus(_addressShop).burn(scrollOwnedID),
            "Cannot burn the scroll!"
        );

        _owners[typeId][_trackers[typeId].current()] = to;
        emit CertificateMinted(to, _trackers[typeId].current());
        _trackers[typeId].increment();
        _certified[typeId][to] = true;
    }

    function _burn(uint256 tokenId, uint256 typeId) private {
        require(_exists(tokenId, typeId), "Nonexistent token");
        emit CertificateBurned(_owners[typeId][tokenId], tokenId);
        _certified[typeId][_owners[typeId][tokenId]] = false;
        _owners[typeId][tokenId] = address(0);
    }
}
