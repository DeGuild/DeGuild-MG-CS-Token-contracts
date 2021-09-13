// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMagicScroll.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MagicScroll is Context, IMagicScroll {
    mapping(uint256 => address) private _owners;
    mapping(uint256 => uint8) private _states;
    address private _minter;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    modifier onlyOwner() {
        require(isOwner(), "Only Owner of the shop has permission to do this");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _minter;
    }

    function forceCancel(uint256 id) external override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _states[id] = 99;
    }

    function consume(uint256 id) external override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _states[id] = 1;
    }

    function burn(uint256 id) external override {
        require(
            _msgSender() == _owners[id],
            "You are not the owner of this item"
        );
        _owners[id] = address(0);
        _states[id] = 0;
    }
}
