// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721 is ERC721, Ownable {
    constructor() ERC721("Makeda NFT", "mNFT") {
        // Mint tokens and assign to test addresses
        _safeMint(address(0x75bD5a94c5a727d1B458b26f546b728159587968), 1);
        _safeMint(address(0xf2750684eB187fF9f82e2F980f6233707eF5768C), 2);
    }
}
