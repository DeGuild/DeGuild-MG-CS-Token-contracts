// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMagicScroll.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MagicScroll is Context, Ownable, IMagicScroll {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    mapping(uint256 => address) private _owners;
    mapping(uint256 => uint8) private _states;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    address _addressDGC;
    string _name;
    string _symbol;

    uint256 _price; //erc20 use 256
    Counters.Counter tracker = Counters.Counter(0);

    constructor(
        string memory name_,
        string memory symbol_,
        address addressDGC_,
        uint256 price_
    ) {
        _name = name_;
        _symbol = symbol_;
        _addressDGC = addressDGC_;
        _price = price_;
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

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function forceCancel(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _states[id] = 99; //Cancelled state id
        emit StateChanged(_states[id]);
    }

    function consume(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _states[id] = 1; //consumed state id
        emit StateChanged(_states[id]);
    }

    function burn(uint256 id) external virtual override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _owners[id] = address(0);
        _states[id] = 0; //burned state id
        emit StateChanged(_states[id]);
    }

    function buyScroll(address buyer)
        external
        virtual
        override
        returns (uint256)
    {
        IERC20 _DGC = IERC20(_addressDGC);
        require(
            _DGC.allowance(buyer, address(this)) >= _price,
            "You do not have enough DGC or you have not approved this token"
        );
        _DGC.transferFrom(buyer, owner(), _price);
        tracker.increment();
        _owners[tracker.current()] = buyer;
        return tracker.current();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
}
