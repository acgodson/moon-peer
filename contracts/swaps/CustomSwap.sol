// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CustomSwap {
    function begin(
        address initiatorParty,
        address counterParty,
        address initiatorToken,
        address counterPartyToken,
        uint256 initiatorAmount,
        uint256 counterPartyAmount
    ) public returns (uint256) {}

    function transferFrom(
        address sender,
        address reciever,
        uint256 amount
    ) public {}

    function complete(uint256 id) public {

    }
}
