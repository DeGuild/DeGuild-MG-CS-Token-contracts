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

    address _addressDGC;
    string _name;
    string _symbol;
    string _baseURIscroll;
    Counters.Counter tracker = Counters.Counter(0);
    Counters.Counter variations = Counters.Counter(0);
    IERC20 _DGC = IERC20(_addressDGC);

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
    function ownerOf(uint256 id) public view virtual override returns (address) {
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

        for (uint256 i = 0; i < tracker.current(); ++i) {
            if (ownerOf(i) == account) {
                balances++;
            }
        }

        uint256[] memory ownedBalances = new uint256[](balances); 
        
        for (uint256 i = 0; i < tracker.current(); ++i) {
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

    function forceCancel(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _scrollCreated[id].state = 99; //Cancelled state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function consume(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _scrollCreated[id].state = 2; //consumed state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function burn(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id] || _msgSender() == owner(),
            "You are not the owner of this item"
        );
        _owners[id] = address(0);
        _scrollCreated[id].state = 0; //burned state id
        emit StateChanged(id, _scrollCreated[id].state);
    }

    function buyScroll(address buyer, uint256 scrollType)
        external
        virtual
        override
        returns (uint256)
    {
        // check for validity to buy from interface for certificate
        require(
            isPurchasableScroll(scrollType),
            "Please earn the prerequisite first!"
        );
        _DGC.transferFrom(buyer, owner(), _scrollTypes[scrollType].price);
        _owners[tracker.current()] = buyer;
        _balances[scrollType][buyer]++;
        emit ScrollBought(tracker.current(), scrollType);
        tracker.increment();
        return tracker.current();
    }

    function addScroll(
        uint256 scrollID,
        address prerequisite,
        bool lessonIncluded,
        bool hasPrerequisite,
        uint256 price
    ) external virtual override returns (uint256) {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: scrollID,
            price: price,
            prerequisite: prerequisite, //certification required
            state: 1,
            lessonIncluded: lessonIncluded,
            hasPrerequisite: hasPrerequisite
        });
        variations.increment();
        return variations.current();
    }

    //This function suppose to be a view function
    function isPurchasableScroll(uint256 scrollType)
        public
        view
        virtual
        returns (bool)
    {
        if(!_scrollTypes[scrollType].hasPrerequisite) return true;
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

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIscroll;
    }
}
