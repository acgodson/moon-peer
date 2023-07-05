// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Makeda ETH", "m_ETH") {
        uint256 amountPerAddress = 500; // Amount to be assigned to each address
        uint256 decimals = 18; // Number of decimals for the token

        // Calculate the token amount with decimals
        uint256 tokenAmount = amountPerAddress * (10 ** decimals);

        // Mint tokens and assign to test addresses
        _mint(address(0x75bD5a94c5a727d1B458b26f546b728159587968), tokenAmount);
        _mint(address(0xf2750684eB187fF9f82e2F980f6233707eF5768C), tokenAmount);
    }
}
