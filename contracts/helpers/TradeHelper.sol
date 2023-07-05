// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../swaps/SwapERC20.sol";
import "../swaps/CustomSwap.sol";
import "./PriorityQueue.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TradeHelper is PriorityQueue, SwapERC20 {
    using SafeMath for uint256;
    enum State {
        BEGUN,
        PARTIAL,
        COMPLETED
    }

    struct Trade {
        uint256 id;
        address initiator;
        uint256 initiatorAmount;
        address initiatorToken;
        address counterPartyToken;
        uint256 counterPartyAmount;
        uint256 balance;
        State state;
        uint256 timestamp;
    }

    struct Fulfillment {
        uint256 amount;
        address payer;
    }

    uint256 public tradeCounter;
    mapping(uint256 => Trade) public trades;
    mapping(bytes32 => uint256[]) private priorityIndex;
    mapping(address => uint256) public tokenPrices;
    mapping(uint256 => Fulfillment[]) public fulfillments;

    function findBestMatch(
        uint256 tradeId
    ) internal view returns (uint256, uint256) {
        Trade storage trade = trades[tradeId];

        bytes32 pairHash = getPairHash(
            trade.counterPartyToken,
            trade.initiatorToken
        );
        SortedTrade[] storage tradeQueue = pairs[pairHash];

        uint256 bestMatchId;
        uint256 highestPriority = 0;
        uint256 earliestTimestamp = block.timestamp; // Initialize with the current timestamp

        for (uint256 i = 0; i < tradeQueue.length; i++) {
            SortedTrade storage sortedTrade = tradeQueue[i];
            Trade storage existingTrade = trades[sortedTrade.id];

            // Matching criteria: Counterparty token and any other conditions
            if (
                existingTrade.balance > 0 &&
                existingTrade.state != State.COMPLETED &&
                sortedTrade.counterPartyAmount > highestPriority
            ) {
                if (sortedTrade.counterPartyAmount > highestPriority) {
                    // Higher priority, update the best match
                    bestMatchId = sortedTrade.id;
                    highestPriority = sortedTrade.counterPartyAmount;
                    earliestTimestamp = existingTrade.timestamp;
                } else if (existingTrade.timestamp < earliestTimestamp) {
                    // Same priority, check timestamp for earlier trade
                    bestMatchId = sortedTrade.id;
                    earliestTimestamp = existingTrade.timestamp;
                }
            }
        }

        if (bestMatchId != 0) {
            return (bestMatchId, highestPriority);
        }

        return (0, 0); // No match found
    }

    function calculatePriority(
        uint256 initiatorAmount,
        address counterPartyToken,
        address initiatorToken
    ) internal view returns (uint256) {
        // Fetch token prices based on token addresses
        uint256 priority = (initiatorAmount * tokenPrices[counterPartyToken]) /
            tokenPrices[initiatorToken];

        return priority;
    }

    function performTrade(
        uint256 tradeId1,
        uint256 tradeId2,
        uint256 availableAmount
    ) internal {
        Trade storage trade1 = trades[tradeId1];
        Trade storage trade2 = trades[tradeId2];

        uint256 fulfillerAmount = trade1.counterPartyAmount > availableAmount
            ? availableAmount
            : trade1.counterPartyAmount;

        //find fulfiller's priority equivalent
        uint256 fulfillerAmountEquivalent = calculatePriority(
            fulfillerAmount,
            trade2.counterPartyToken,
            trade2.initiatorToken
        );

        //start a pending swap
        begin(
            trade1.initiator,
            trade2.initiator,
            trade1.initiatorToken,
            trade2.initiatorToken,
            fulfillerAmount,
            fulfillerAmountEquivalent,
            trade1.id,
            trade2.id
        );

        // Update trade1 and trade2 balances
        trade1.balance -= fulfillerAmount;
        trade2.balance -= fulfillerAmount;

        // Update trade states

        trade1.state = State.PARTIAL;
        trade2.state = State.PARTIAL;
    }

    function getPairHash(
        address token1,
        address token2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token1, token2));
    }

    function updateTradeStates(uint256 tradeId1, uint256 tradeId2) internal {
        Trade storage trade1 = trades[tradeId1];
        Trade storage trade2 = trades[tradeId2];

        // Update trade states
        // ...
        // Update trade states to COMPLETED
        trade1.state = State.PARTIAL;
        trade2.state = State.PARTIAL;
    }


}
