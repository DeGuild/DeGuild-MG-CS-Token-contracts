// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SkillCertificates/ISkillCertificate.sol";
import "./IMagicScrolls.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MagicScrolls is Context, Ownable, IMagicScrolls {
    /**
     * Libraries required, please use these!
     */
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    struct MagicScroll {
        uint256 scrollID;
        uint256 price;
        address prerequisite; //certification required, check for existence and validity
        uint8 state;
        bool lessonIncluded;
        bool hasPrerequisite;
        bool available;
    }

    /**
     * @dev Classic ERC721 mapping, tracking down the scrolls existed
     * We need to know exactly what happened to the scroll
     * so we keep track of those scrolls here.
     */
    mapping(uint256 => address) private _owners;
    mapping(uint256 => MagicScroll) private _scrollCreated;

    mapping(uint256 => MagicScroll) private _scrollTypes;

    /**
     * @dev Classic ERC1155 mapping, tracking down the balances of each address
     * Given a scroll type and an address, we know the quantity!
     */
    mapping(uint256 => mapping(address => uint256)) private _balances;

    address private _addressDGC;
    string private _name;
    string private _symbol;
    string private _baseURIscroll;
    Counters.Counter private tracker = Counters.Counter(0);
    Counters.Counter private variations = Counters.Counter(0);
    IERC20 private _DGC;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address addressDGC_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGC = addressDGC_;
        _baseURIscroll = baseURI_;
        _DGC = IERC20(addressDGC_);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
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
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
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
     * @dev Telling what this address own
     */
    function balanceUserOwned(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 balances = 0;

        for (uint256 i = 0; i < tracker.current(); i++) {
            if (ownerOf(i) == account) {
                balances++;
            }
        }

        uint256[] memory ownedBalances = new uint256[](balances);

        for (uint256 i = tracker.current() - 1; i > 0; i--) {
            if (ownerOf(i) == account) {
                ownedBalances[--balances] = i;
            }
        }
        return ownedBalances;
    }

    /**
     * @dev Check every type of scroll in one account
     *
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
     * @dev Check every type of scroll in one account, check the struct to decode it properly
     *
     */
    function scrollTypes() public view virtual returns (MagicScroll[] memory) {
        MagicScroll[] memory batchBalances = new MagicScroll[](
            variations.current()
        );

        for (uint256 i = 0; i < variations.current(); ++i) {
            batchBalances[i] = _scrollTypes[i];
        }
        return batchBalances;
    }

    /**
     * @dev Check every type of scroll in one account
     *
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
        require(_existsType(typeId), "This scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[typeId];
        return (
            typeId,
            scroll.scrollID,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev Check every type of scroll in one account
     *
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
            address,
            bool,
            bool,
            bool
        )
    {
        require(_existsType(tokenId), "This scroll type does not exist");
        MagicScroll memory scroll = _scrollTypes[tokenId];
        return (
            tokenId,
            scroll.scrollID,
            scroll.price,
            scroll.prerequisite,
            scroll.lessonIncluded,
            scroll.hasPrerequisite,
            scroll.available
        );
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the acceptable token name.
     */
    function deguildCoin() external view virtual override returns (address) {
        return _addressDGC;
    }

    /**
     * @dev Returns the token collection name.
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
     * @dev Returns the token collection symbol.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
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

    function forceCancel(uint256 id) external virtual override returns (bool) {
        require(_exists(id), "Nonexistent token");
        require(
            _msgSender() == _owners[id] || _msgSender() == owner(),
            "You are not the owner of this item"
        );
        _scrollCreated[id].state = 99; //Cancelled state id
        emit StateChanged(id, _scrollCreated[id].state);
        return true;
    }

    function consume(uint256 id) external virtual override returns (bool) {
        require(_exists(id), "Nonexistent token");

        require(
            _msgSender() == _owners[id] || _msgSender() == owner(),
            "You are not the owner of this item"
        );
        require(
            _scrollCreated[id].state == 1,
            "This scroll is no longer consumable."
        );
        _scrollCreated[id].state = 2; //consumed state id
        emit StateChanged(id, _scrollCreated[id].state);
        return true;
    }

    function burn(uint256 id) external virtual override returns (bool) {
        require(_exists(id), "Nonexistent token");
        require(
            _msgSender() == _scrollCreated[id].prerequisite ||
                _msgSender() == owner(),
            "You are not the certificate manager, burning is reserved for the claiming certificate only."
        );
        require(
            _scrollCreated[id].state == 1 || _scrollCreated[id].state == 2,
            "This scroll is no longer burnable."
        );
        MagicScroll memory scroll = _scrollCreated[id];
        _owners[id] = address(0);
        scroll.state = 0; //burned state id
        emit StateChanged(id, _scrollCreated[id].state);
        _balances[scroll.scrollID][ownerOf(id)]--;
        return true;
    }

    function buyScroll(uint256 scrollType)
        external
        virtual
        override
        returns (bool)
    {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType),
            "Please earn the prerequisite first!"
        );
        require(
            _DGC.transferFrom(
                _msgSender(),
                owner(),
                _scrollTypes[scrollType].price
            ),
            "Cannot transfer DGC, approve the contract or buy more DGC!"
        );
        _scrollCreated[tracker.current()] = _scrollTypes[scrollType];
        _owners[tracker.current()] = _msgSender();
        _balances[scrollType][_msgSender()]++;

        emit ScrollBought(tracker.current(), scrollType);
        tracker.increment();
        return true;
    }

    function addScroll(
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external virtual override onlyOwner returns (bool) {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: variations.current(),
            price: price,
            prerequisite: prerequisite, //certification required
            state: 1,
            lessonIncluded: lessonIncluded,
            hasPrerequisite: hasPrerequisite,
            available: true
        });
        emit ScrollAdded(
            variations.current(),
            price,
            prerequisite,
            lessonIncluded,
            hasPrerequisite,
            true
        );
        variations.increment();
        return true;
    }

    function sealScroll(uint256 scrollType)
        external
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_existsType(scrollType), "This scroll type does not exist");
        _scrollTypes[scrollType].available = false;
        emit ScrollAdded(
            _scrollTypes[scrollType].scrollID,
            _scrollTypes[scrollType].price,
            _scrollTypes[scrollType].prerequisite,
            _scrollTypes[scrollType].lessonIncluded,
            _scrollTypes[scrollType].hasPrerequisite,
            _scrollTypes[scrollType].available
        );
        return true;
    }

    //This function suppose to be a view function
    function isPurchasableScroll(uint256 scrollType)
        public
        view
        virtual
        returns (bool)
    {
        require(_existsType(scrollType), "Scroll does not exist.");
        if (!_scrollTypes[scrollType].hasPrerequisite) return true;
        require(
            ISkillCertificate(_scrollTypes[scrollType].prerequisite).verify(
                _msgSender()
            ),
            "You are not verified"
        );
        return true;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _existsType(uint256 tokenId) internal view virtual returns (bool) {
        return variations.current() > tokenId;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }
}
