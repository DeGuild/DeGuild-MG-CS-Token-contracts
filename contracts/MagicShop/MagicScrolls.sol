// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMagicScrolls.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MagicScrolls is Context, Ownable, IMagicScrolls {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    struct MagicScroll {
        uint256 scrollID;
        uint256 price;
        address prerequisite; //certification required
        uint8 state;
        bool lessonIncluded;
        string scrollURI;
    }

    mapping(uint256 => address) private _owners;
    mapping(uint256 => MagicScroll) private _scrollCreated;
    mapping(uint256 => MagicScroll) private _scrollTypes;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    address _addressDGC;
    string _name;
    string _symbol;
    string _baseURIscroll;
    Counters.Counter tracker = Counters.Counter(0);
    Counters.Counter variations = Counters.Counter(0);

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
            _msgSender() == _owners[id],
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
        IERC20 _DGC = IERC20(_addressDGC);
        _DGC.transferFrom(buyer, owner(), _scrollTypes[scrollType].price);
        _owners[tracker.current()] = buyer;
        tracker.increment();
        return tracker.current();
    }

    function addScroll(
        uint256 _scrollID,
        address _prerequisite,
        bool _lessonIncluded,
        uint256 _price,
        string memory _scrollURI
    ) external virtual returns (uint256) {
        _scrollTypes[variations.current()] = MagicScroll({
            scrollID: _scrollID,
            price: _price,
            prerequisite: _prerequisite, //certification required
            state: 1,
            lessonIncluded: _lessonIncluded,
            scrollURI: _scrollURI
        });
        variations.increment();
        return variations.current();
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
