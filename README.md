# Email-as-ENS Registrar

A decentralized registrar that allows users to claim ENS names based on their email ownership using zk-email proofs.

## Overview

This project enables users to claim ENS names corresponding to their email addresses. For example, if you own "myemail@example.com", you can claim "myemail@example.com.email.eth" and set any Ethereum address as the owner.

The system uses zk-email proofs to verify email ownership, ensuring that only the legitimate owner of an email address can claim the corresponding ENS name.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for testing)
- Git

## Setup

1. Clone the repository:
```shell
git clone https://github.com/yourusername/email-as-ens.git
cd email-as-ens
```

2. Install dependencies:
```shell
forge install
```

2.5 Install npm dependencies of `lib/openzeppelin-community-contracts`
```
cd lib/openzeppelin-community-contracts
npm install
cd ../..
```

3. Build the project:
```shell
forge build
```

## Development

### Testing

```shell
forge test
```

### Format Code

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Local Development

Start a local Ethereum node:
```shell
anvil
```

## Project Structure

- `src/` - Smart contract source files
  - `ZKEmailRegistrar.sol` - Main registrar contract
- `test/` - Tests

## Foundry Documentation

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

For more information, visit the [Foundry Book](https://book.getfoundry.sh/).

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
