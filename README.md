# Moon Peer

👉 [Video Demo](https://youtu.be/Hw20m7ySP8U)

## Description

### Peer-2-peer escrow contract.

<br/>
Users submit trade orders, which are then matched with existing orders based on their priority level. The contract supports both partial and complete trades, enabling users to specify the desired quantity of tokens for each trade.

The contract heavily relies on moonbeam `batch.sol` precompile to submit trade orders and give escrow contract approval to send tokens on behalf of trader

## Features

- Peer-to-peer approval
- Order size Priority matching
- Time Priority matching
- Price Priority matching

## Requirements

HardHat and Nodejs Installed

```bash

git clone "https://github,com/acgodson/moon-peer"
cd Smart-Contract
npm install
```

Test Contract

```bash
npx hardhat test
```
