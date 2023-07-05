// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TradeContract.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract TradeFactory {
    event SpaceCreated(uint256 indexed spaceId, address indexed owner);

    bytes32 public salt;

    struct Space {
        uint256 id;
        address escrow;
        address[] tokens;
        uint256[] prices;
    }

    uint256 public spaceCounter;
    mapping(address => Space[]) public spaces;

    function createSpace(
        address[] memory _tokens,
        uint256[] memory _prices
    ) external {
        require(
            _tokens.length == _prices.length,
            "Mismatch between tokens and prices"
        );
        spaceCounter++;

        uint256 id = spaceCounter;
        Space memory space = Space({
            id: id,
            escrow: address(0),
            tokens: _tokens,
            prices: _prices
        });
        spaces[msg.sender].push(space);

        createEscrow(space.id);

        emit SpaceCreated(space.id, msg.sender);
    }

    function createEscrow(uint256 spaceId) internal {
        Space[] storage userSpaces = spaces[msg.sender];

        require(userSpaces.length > 0, "Invalid spaceId");

        Space storage space = userSpaces[userSpaces.length - 1];

        //  // Retrieve participants and shares for the space
        address[] storage tokens = space.tokens;
        uint256[] storage prices = space.prices;

        // // Generate salt using the spaceID and the deploymentNonce
        salt = keccak256(abi.encode(spaceId));

        // // Compute the expected address based on the deployment bytecode and salt
        bytes memory bytecode = type(TradeContract).creationCode;
        address expectedAddress = Create2.computeAddress(
            salt,
            keccak256(bytecode)
        );

        // Create an escrow contract
        address escrow = Create2.deploy(0, salt, bytecode);
        TradeContract(escrow).initialize(tokens, prices);

        // Require the deployed address to be equal to the expected address
        require(
            address(escrow) == expectedAddress,
            "Deployed address does not match the expected address"
        );

        // Store the escrow address in the space
        space.escrow = address(escrow);
        return;
    }

    function getSpaces(address owner) external view returns (Space[] memory) {
        return spaces[owner];
    }
}
