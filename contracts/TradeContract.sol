// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/PriorityQueue.sol";
import "./helpers/TradeHelper.sol";
import "./swaps/SwapERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract TradeContract is TradeHelper, Initializable {
    function initialize(
        address[] memory _tokens,
        uint256[] memory _prices
    ) public initializer {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 price = _prices[i];
            require(token != address(0), "Invalid token address");
            require(price > 0, "Invalid price");

            tokenPrices[token] = price;
        }
        tradeCounter = 1;
    }

    function getMatches(
        address initiatorToken,
        uint256 initiatorAmount,
        address counterPartyToken
    ) external view returns (Trade[] memory) {
        require(initiatorAmount > 0, "Invalid initiator amount");

        Trade[] memory matches = new Trade[](tradeCounter); // Use a fixed-size array
        uint256 matchCount = 0; // Keep track of the number of matches

        uint256 remainingAmount = initiatorAmount;

        bytes32 pairHash = getPairHash(counterPartyToken, initiatorToken);
        SortedTrade[] storage tradeQueue = pairs[pairHash];

        require(tradeQueue.length > 0, "No matching trades found");

        uint256 highestPriority = 0;

        // Find the highest priority trade that covers the initiatorAmount
        for (uint256 i = 0; i < tradeQueue.length; i++) {
            SortedTrade storage sortedTrade = tradeQueue[i];
            Trade storage existingTrade = trades[sortedTrade.id];

            if (
                existingTrade.balance > 0 &&
                existingTrade.state != State.COMPLETED &&
                sortedTrade.counterPartyAmount > highestPriority
            ) {
                highestPriority = sortedTrade.counterPartyAmount;
            }
        }

        // Retrieve all matching trades that cover the initiatorAmount
        for (uint256 i = 0; i < tradeQueue.length; i++) {
            SortedTrade storage sortedTrade = tradeQueue[i];
            Trade storage existingTrade = trades[sortedTrade.id];

            if (
                existingTrade.balance > 0 &&
                existingTrade.state != State.COMPLETED
            ) {
                // Calculate available amount based on remaining balance
                uint256 availableAmount = existingTrade.balance >
                    remainingAmount
                    ? remainingAmount
                    : existingTrade.balance;

                // Create a copy of the trade
                Trade memory matchTrade = existingTrade;
                matchTrade.balance = availableAmount; // Set the balance to the available amount

                matches[matchCount] = matchTrade; // Add the match to the array
                matchCount++;
                remainingAmount -= availableAmount;
            }
        }

        // Create a new dynamic array with the correct length
        Trade[] memory finalMatches = new Trade[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            finalMatches[i] = matches[i];
        }

        return finalMatches;
    }

    function submitTradeOrder(
        uint256[] memory matchingTradeIds,
        uint256 initiatorAmount,
        address initiatorToken,
        address counterPartyToken
    ) external returns (Trade memory) {
        require(initiatorAmount > 0, "Invalid initiator amount");

        // submit deposit in escrow contract
        // require(
        //     IERC20(initiatorToken).transferFrom(
        //         msg.sender,
        //         address(this),
        //         initiatorAmount
        //     ),
        //     "ERC20 transfer failed"
        // );

        // Calculate the priority based on counterPartyAmount
        uint256 priority = calculatePriority(
            initiatorAmount,
            counterPartyToken,
            initiatorToken
        );

        // Create a new trade
        Trade memory newTrade = Trade({
            id: tradeCounter,
            initiator: msg.sender,
            initiatorAmount: initiatorAmount,
            initiatorToken: initiatorToken,
            counterPartyToken: counterPartyToken,
            counterPartyAmount: priority,
            balance: initiatorAmount,
            state: State.BEGUN,
            timestamp: block.timestamp
        });

        trades[newTrade.id] = newTrade;
        tradeCounter++;

        // Add trade to the priority index
        bytes32 pairHash = getPairHash(initiatorToken, counterPartyToken);
        enqueue(newTrade.id, priority, pairHash);
        // Process the provided matching trade IDs
        for (uint256 i = 0; i < matchingTradeIds.length; i++) {
            uint256 matchingTradeId = matchingTradeIds[i];
            // Trade storage existingTrade = trades[matchingTradeId];
            // if (matchingTradeId != newTrade.id) {

            //     uint256 availableAmount = existingTrade.balance >
            //         newTrade.balance
            //         ? newTrade.balance
            //         : existingTrade.balance;
            // }

            performTrade(newTrade.id, matchingTradeId, 200);
        }
        // Perform trade between new trade and existing trade

        return newTrade; // No match found
    }

    function getTrade(uint256 tradeId) external view returns (Trade memory) {
        return trades[tradeId];
    }

    function updateTokenPrice(address token, uint256 price) external {
        tokenPrices[token] = price;
    }

    function getPendingSwaps(
        uint256 initiatorTradeID,
        address[] memory addresses
    ) external returns (Swap[] memory) {
        uint256[] memory pendingSwapIds;
        uint256 pendingSwapCount = 0;

        // Loop through each address
        for (uint256 j = 0; j < addresses.length; j++) {
            address matchingAddress = addresses[j];
            uint256[] memory swapIds = swapIdsByAddress[matchingAddress];

            // Find pending swaps with the same initiatorTradeID
            for (uint256 i = 0; i < swapIds.length; i++) {
                uint256 swapId = swapIds[i];
                Swap storage swap = swaps[swapId];

                if (
                    swap.initiatorTradeID == initiatorTradeID && !swap.completed
                ) {
                    // Resize the pendingSwapIds array if necessary
                    if (pendingSwapCount == pendingSwapIds.length) {
                        uint256 newSize = pendingSwapCount == 0
                            ? 1
                            : pendingSwapCount * 2;
                        uint256[] memory newPendingSwapIds = new uint256[](
                            newSize
                        );
                        for (uint256 k = 0; k < pendingSwapCount; k++) {
                            newPendingSwapIds[k] = pendingSwapIds[k];
                        }
                        pendingSwapIds = newPendingSwapIds;
                    }

                    pendingSwapIds[pendingSwapCount] = swap.id; // Store the swap ID instead of swapId
                    pendingSwapCount++;
                }
            }
        }

        // Create an array to store the pending swaps
        Swap[] memory pendingSwaps = new Swap[](pendingSwapCount);
        for (uint256 i = 0; i < pendingSwapCount; i++) {
            uint256 swapId = pendingSwapIds[i];
            pendingSwaps[i] = swaps[swapId];
            completeSwap(pendingSwaps[i]);
        }

        return pendingSwaps;
    }

    function cancelSwap(uint256 id) external {
        Swap storage swap = swaps[id];
        Trade storage counterPartyTrade = trades[swap.counterPartyTradeID];
        Trade storage initiatorTrade = trades[swap.initiatorTradeID];

        require(
            swap.initiator == msg.sender || swap.counterParty == msg.sender,
            "Only initiator or counterParty can cancel the swap"
        );
        require(swap.completed == false, "Swap already completed");

        IERC20 initiatorToken = IERC20(swap.initiatorToken);
        IERC20 counterPartyToken = IERC20(swap.counterPartyToken);

        uint256 initiatorAmount = swap.initiatorAmount;
        uint256 counterPartyAmount = swap.counterPartyAmount;
        address counterParty = swap.counterParty;
        address initiator = swap.initiator;

        // Transfer tokens from the contract to the initiator
        require(
            initiatorToken.transferFrom(
                address(this),
                initiator,
                initiatorAmount
            ),
            "Transfer failed"
        );

        // Transfer tokens from the contract to the counterParty
        require(
            counterPartyToken.transferFrom(
                address(this),
                counterParty,
                counterPartyAmount
            ),
            "Transfer failed"
        );

        // Update balances
        counterPartyTrade.balance += counterPartyAmount;
        initiatorTrade.balance += initiatorAmount;

        // Delete the swap from the mapping
        delete swaps[id];
        emit SwapCancelled(id);
    }

    function completeSwap(Swap memory swap) internal {
        Trade storage counterPartyTrade = trades[swap.counterPartyTradeID];
        Trade storage initiatorTrade = trades[swap.initiatorTradeID];

        // require(swap.completed != true, "Trade already completed");

        // For Test, let's work with just ERC20 swap

        // Swap storage xen = swaps[swap.id];

        // IERC20 initiatorToken = IERC20(swap.initiatorToken);
        // IERC20 counterPartyToken = IERC20(swap.counterPartyToken);

        // uint256 initiatorAmount = swap.initiatorAmount;
        // uint256 counterPartyAmount = swap.counterPartyAmount;
        // address counterParty = swap.counterParty;
        // address initiator = swap.initiator;

        // transfer to fulfiller
        // require(
        //     initiatorToken.transfer(counterParty, initiatorAmount),
        //     "Transfer to counterParty failed"
        // );
        // // transfer to initiator
        // require(
        //     counterPartyToken.transfer(initiator, counterPartyAmount),
        //     "Transfer to initiator failed"
        // );

        swap.completed = true;
        emit SwapCompleted(swap.id);

        // Update trade states
        if (counterPartyTrade.balance == 0) {
            counterPartyTrade.state = State.COMPLETED;
        }
        if (initiatorTrade.balance == 0) {
            initiatorTrade.state = State.COMPLETED;
        }

        // Update fulfillments
        Fulfillment memory forFulfiller = Fulfillment({
            amount: swap.initiatorAmount,
            payer: swap.initiator
        });

        Fulfillment memory forIntiiator = Fulfillment({
            amount: swap.counterPartyAmount,
            payer: swap.counterParty
        });
        fulfillments[swap.counterPartyTradeID].push(forFulfiller);
        fulfillments[swap.initiatorTradeID].push(forIntiiator);
    }
}
