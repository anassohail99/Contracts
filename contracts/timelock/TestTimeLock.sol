// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract TestTimeLock {
    address public timeLock;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    function Test() external view {
        require(msg.sender == timeLock, "NO");
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp + 100;
    }
}
