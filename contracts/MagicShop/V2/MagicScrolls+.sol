// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/SkillCertificates/V2/ISkillCertificate+.sol";
import "./IMagicScrolls+.sol";
import "contracts/Utils/EIP-55.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract MagicScrollsPlus is Context, Ownable, IMagicScrollsPlus {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;
    using ChecksumLib for address;
    using ERC165Checker for address;

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;

    /**
     * @dev This mapping store all scrolls.
     */
    mapping(uint256 => MagicScroll) private _scrollCreated;

    /**
     * @dev This mapping store just scroll types.
     */
    mapping(uint256 => MagicScroll) private _scrollTypes;

    /**
     * @dev Classic ERC1155 mapping, tracking down the balances of each address
     * Given a scroll type and an address, we know the quantity!
     */
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /**
     * @dev This mapping handles permission to use burn().
     */
    mapping(address => bool) private _certificateManagers;

    /**
     * @dev Store the address of Deguild Token
     */
    address private _addressDGT;
    string private _name;
    string private _symbol;
    string private _baseURIscroll;

    /**
     * @dev Store the ID of scrolls and types
     */
    Counters.Counter private tracker = Counters.Counter(0);
    Counters.Counter private variations = Counters.Counter(0);

    /**
     * @dev Store the interface of Deguild Token
     */
    IERC20 private _DGT;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressDGT_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGT = addressDGT_;
        _baseURIscroll = baseURI_;
        _DGT = IERC20(addressDGT_);
    }

    /**
     * @dev See {IMagicScrollsPlus-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IMagicScrollsPlus-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IMagicScrollsPlus-tokenURI}.
     *
     * Requirements:
     *
     * - `tokenId` cannot be non-existence token.
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
            "IMagicScrollsPlus: URI query for nonexistent scroll"
        );

        uint256 tokenType = _scrollCreated[tokenId].scrollID;
        return tokenTypeURI(tokenType);
    }

    /**
     * @dev See {IMagicScrollsPlus-tokenURI}.
     *
     * Requirements:
     *
     * - `tokenTypeId` cannot be non-existence token.
     */
    function tokenTypeURI(uint256 tokenTypeId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _existsType(tokenTypeId),
            "IMagicScrollsPlus: URI query for nonexistent scroll type"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        abi.encodePacked(baseURI, address(this).getChecksum()),
                        abi.encodePacked("/", tokenTypeId.toString())
                    )
                )
                : "";
    }

    /**
     * @dev See {IMagicScrollsPlus-numberOfScrollTypes}.
     */
    function numberOfScrollTypes()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return variations.current();
    }

    /**
     * @dev See {IMagicScrollsPlus-deguildCoin}.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGT;
    }

    /**
     * @dev See {IMagicScrollsPlus-ownerOf}.
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
            "IMagicScrollsPlus: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IMagicScrollsPlus-balanceOfOne}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOfOne(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "IMagicScrollsPlus: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IMagicScrollsPlus-balanceOfAll}.
     */
    function balanceOfAll(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](variations.current());

        for (uint256 i = 0; i < variations.current(); ++i) {
            batchBalances[i] = balanceOfOne(account, i);
        }

        return batchBalances;
    }

    /**
     * @dev See {IMagicScrollsPlus-balanceUserOwned}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceUserOwned(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            account != address(0),
            "IMagicScrollsPlus: balance query for the zero address"
        );
        uint256 balances = 0;

        for (uint256 i = 0; i < tracker.current(); i++) {
            if (_owners[i] == account) {
                balances++;
            }
        }

        uint256[] memory ownedBalances = new uint256[](balances);

        for (uint256 i = tracker.current() - 1; i > 0; i--) {
            if (_owners[i] == account) {
                ownedBalances[--balances] = i;
            }
        }
        return ownedBalances;
    }

    /**
     * @dev See {IMagicScrollsPlus-isCertificateManager}.
     */
    function isCertificateManager(address manager)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _certificateManagers[manager];
    }

    /**
     * @dev See {IMagicScrollsPlus-isPurchasableScroll}.
     *
     * Requirements:
     *
     * - `scrollType` must exist.
     * - `scrollType` must be available.
     * -  If it has a prerequisite, `scrollType`'s prerequisite must
     *    supports ISkillCertificatePlus interface (ERC165).
     */
    function isPurchasableScroll(uint256 scrollType, address buyer)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(_existsType(scrollType), "IMagicScrollsPlus: scroll does not exist.");
        require(
            _scrollTypes[scrollType].available,
            "IMagicScrollsPlus: this scroll type is no longer purchasable"
        );

        if (!_scrollTypes[scrollType].hasPrerequisite) {
            return true;
        } else {
            require(
                _scrollTypes[scrollType].prerequisite.supportsInterface(
                    type(ISkillCertificatePlus).interfaceId
                ),
                "IMagicScrollsPlus: ISkillCertificatePlus is not supported by this address"
            );
            return
                ISkillCertificatePlus(_scrollTypes[scrollType].prerequisite)
                    .verify(buyer, _scrollTypes[scrollType].certificateId);
        }
    }

    /**
     * @dev See {IMagicScrollsPlus-scrollTypes}.
     */
    function scrollTypes()
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory types;
        uint256 count = 0;

        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                count++;
            }
        }

        types = new uint256[](count);
        for (uint256 i = 0; i < variations.current(); i++) {
            if (_scrollTypes[i].available) {
                types[--count] = i;
            }
        }
        return types;
    }

    /**
     * @dev See {IMagicScrollsPlus-scrollTypeInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollTypeInfo(uint256 typeId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool,
            bool
        )
    {
        require(_existsType(typeId), "IMagicScrollsPlus: this scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[typeId];
        return (
            typeId,
            scroll.price,
            scroll.certificateId,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev See {IMagicScrollsPlus-scrollInfo}.
     *
     * Requirements:
     *
     * - `id` must exist.
     */
    function scrollInfo(uint256 tokenId)
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        )
    {
        require(_exists(tokenId), "IMagicScrollsPlus: this scroll does not exist");
        MagicScroll memory scroll = _scrollCreated[tokenId];
        return (
            tokenId,
            scroll.scrollID,
            scroll.price,
            scroll.certificateId,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite
        );
    }

    /**
     * @dev See {IMagicScrollsPlus-forceCancel}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner of the shop.
     */
    function forceCancel(uint256 id) external virtual override returns (bool) {
        _forceCancel(id);
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-consume}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be the owner.
     * - The scroll state must be 1 (minted).
     */
    function consume(uint256 id, string memory data)
        external
        virtual
        override
        returns (bool)
    {
        _consume(id, data);
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-burn}.
     *
     * Requirements:
     *
     * - `id` must exist.
     * - The caller must be a certificate manager (ERC165 & Approved).
     * - The scroll state must be 1 (minted) or 2 (consumed).
     */
    function burn(uint256 id) external virtual override returns (bool) {
        _burn(id);
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-buyScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must be purchasable.
     * - The caller must be able to transfer DGT properly and succesfully.
     */
    function buyScroll(uint256 scrollType)
        external
        virtual
        override
        returns (bool)
    {
        _buyScroll(scrollType);
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-addScroll}.
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
    ) external virtual override onlyOwner returns (bool) {
        _addScroll(
            certificateId,
            prerequisite,
            lessonIncluded,
            hasPrerequisite,
            price
        );
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-setCertificateManager}.
     *
     * Requirements:
     *
     * - The caller must be the owner of the shop.
     */
    function setCertificateManager(address manager, bool status)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _certificateManagers[manager] = status;
        emit ApprovalForCM(manager, status);
        return true;
    }

    /**
     * @dev See {IMagicScrollsPlus-sealScroll}.
     *
     * Requirements:
     *
     * - `scroll` type must exist.
     * - The caller must be the owner of the shop.
     */
    function sealScroll(uint256 scrollType)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        _sealScroll(scrollType);
        return true;
    }

    function _addScroll(
        uint256 certificateId,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) private {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: variations.current(),
            price: price,
            certificateId: certificateId,
            prerequisite: prerequisite, //certification required
            state: 1,
            lessonIncluded: lessonIncluded,
            hasPrerequisite: hasPrerequisite,
            available: true
        });
        emit ScrollAdded(variations.current());
        variations.increment();
    }

    function _sealScroll(uint256 scrollType) private returns (bool) {
        require(_existsType(scrollType), "IMagicScrollsPlus: this scroll type does not exist");

        _scrollTypes[scrollType].available = false;
        return true;
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _existsType(uint256 tokenId) private view returns (bool) {
        require(
            variations.current() > tokenId,
            "IMagicScrollsPlus: there are not that many types of scroll"
        );
        return _scrollTypes[tokenId].available;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() private view returns (string memory) {
        return _baseURIscroll;
    }

    function _buyScroll(uint256 scrollType) private {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType, _msgSender()),
            "IMagicScrollsPlus: this scroll is not purchasable."
        );
        require(
            _DGT.transferFrom(
                _msgSender(),
                owner(),
                _scrollTypes[scrollType].price
            ),
            "IMagicScrollsPlus: cannot transfer DGT"
        );
        _scrollCreated[tracker.current()] = _scrollTypes[scrollType];
        _owners[tracker.current()] = _msgSender();
        _balances[scrollType][_msgSender()]++;

        emit ScrollBought(tracker.current(), scrollType, _msgSender());
        tracker.increment();
    }

    function _burn(uint256 id) private {
        require(_exists(id), "IMagicScrollsPlus: owner query fo nonexistent token");
        require(
            _msgSender().supportsInterface(
                type(ISkillCertificatePlus).interfaceId
            ),
            "IMagicScrollsPlus: ISkillCertificatePlus is not supported by caller"
        );
        require(
            isCertificateManager(_msgSender()),
            "IMagicScrollsPlus: caller is not the approved certificate manager."
        );
        require(
            _scrollCreated[id].state == 1 || _scrollCreated[id].state == 2,
            "IMagicScrollsPlus: this scroll is no longer burnable."
        );
        _balances[_scrollCreated[id].scrollID][ownerOf(id)]--;
        _scrollCreated[id].state = 0; //consumed state id
        _owners[id] = address(0);
        emit ScrollBurned(id, _msgSender());
    }

    function _forceCancel(uint256 id) private onlyOwner {
        require(_exists(id), "IMagicScrollsPlus: owner query for nonexistent token");
        _scrollCreated[id].state = 99; //Cancelled state id
        _owners[id] = address(0);
    }

    function _consume(uint256 id, string memory data) internal virtual {
        require(_exists(id), "IMagicScrollsPlus: owner query for nonexistent token");
        require(
            _owners[id] == _msgSender(),
            "IMagicScrollsPlus: must be consumed by the owner"
        );
        require(
            _scrollCreated[id].state == 1,
            "IMagicScrollsPlus: this scroll is no longer consumable."
        );
        _scrollCreated[id].state = 2; //consumed state id
        emit ScrollConsumed(id, keccak256(abi.encodePacked(data)));
    }
}
