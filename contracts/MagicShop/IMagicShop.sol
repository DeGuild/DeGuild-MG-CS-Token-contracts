// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagicShop {
    
    function buyScroll(uint256 id, uint32 count, address to) external returns (uint256);

    function addScroll(uint64 price, string memory name, string memory courseId, string memory preCourseId) external returns (uint256);

}
