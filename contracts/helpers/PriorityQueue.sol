// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriorityQueue {
    struct SortedTrade {
        uint256 id;
        uint256 counterPartyAmount;
    }

    SortedTrade[] private trades;

    mapping(bytes32 => SortedTrade[]) public pairs;

    function size() public view returns (uint256) {
        return trades.length;
    }

    function enqueue(
        uint256 id,
        uint256 counterPartyAmount,
        bytes32 pairHash
    ) internal {
        // Create a new trade object with the provided id and counterPartyAmount
        SortedTrade memory trade = SortedTrade({
            id: id,
            counterPartyAmount: counterPartyAmount
        });

        // Get the trade queue for the given pair hash
        SortedTrade[] storage tradeQueue = pairs[pairHash];

        // Find the correct position to insert the new trade based on its priority
        uint256 i = tradeQueue.length;
        while (
            i > 0 &&
            trade.counterPartyAmount > tradeQueue[i - 1].counterPartyAmount
        ) {
            i--;
        }

        // Insert the trade at the correct position
        tradeQueue.push(trade);
        if (i < tradeQueue.length - 1) {
            for (uint256 j = tradeQueue.length - 1; j > i; j--) {
                tradeQueue[j] = tradeQueue[j - 1];
            }
            tradeQueue[i] = trade;
        }
    }

    function dequeue(uint256 id, bytes32 pairHash) internal {
        SortedTrade[] storage tradeQueue = pairs[pairHash];
        for (uint256 i = 0; i < tradeQueue.length; i++) {
            if (tradeQueue[i].id == id) {
                if (i != tradeQueue.length - 1) {
                    for (uint256 j = i; j < tradeQueue.length - 1; j++) {
                        tradeQueue[j] = tradeQueue[j + 1];
                    }
                }
                tradeQueue.pop();
                break;
            }
        }
    }

    function getSortedIdsDesc(
        bytes32 pairHash
    ) public view returns (uint256[] memory) {
        SortedTrade[] storage queue = pairs[pairHash];
        uint256[] memory sortedIds = new uint256[](queue.length);

        for (uint256 i = 0; i < queue.length; i++) {
            sortedIds[i] = queue[i].id;
        }

        quickSortDesc(sortedIds, int256(0), int256(queue.length - 1));

        return sortedIds;
    }

    function quickSortDesc(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint256(i)] > pivot) {
                i++;
            }
            while (arr[uint256(j)] < pivot) {
                j--;
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) {
            quickSortDesc(arr, left, j);
        }
        if (i < right) {
            quickSortDesc(arr, i, right);
        }
    }
}
