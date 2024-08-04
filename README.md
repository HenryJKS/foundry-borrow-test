# Borrow Smart Contract

## Overview

The `Borrow` smart contract is designed to facilitate loans using an ERC-20 token as collateral. Users can take out loans based on their staked tokens, and the contract manages loan terms, payments, and the ability to deny users under certain circumstances.

## Contract Structure

### Dependencies

The `Borrow` contract depends on two other contracts:
- `MyToken`: An ERC-20 token contract used for managing token transactions.
- `Stake`: A staking contract that manages user stakes.

### Constructor

```solidity
constructor(address addrStake)
```

- Initializes the Borrow contract with an instance of the Stake contract.
- Sets the MyToken instance by retrieving the token address from the Stake contract.

### Modifiers
- onlyOwner: Restricts function access to the owner of the MyToken.

### Enums
| Enum Name      | Values | Description |
| ----------- | ----------- | ----------- |
| `LoanStatus`| `PaidOut`, `NotPay` | Represents the current status of a loan.
| `ReasonDeny`| `PaymentLate`, `BadConduct`, `Others` | Reasons for denying a user from taking out a loan.

### State Variables
|Variable Name	|Type	|Description|
| ----------- | ----------- | ----------- |
|stakeInstance	|StakeInstance	|Instance of the staking contract|
|myToken	|MyToken|	Instance of the token contract|
|userLoans	|mapping|	Stores loan details for each user|
|userDeny	|mapping|	Tracks whether a user has been denied loans|
|VALUEVERIFYMIN	|uint256|	Minimum amount for loan verification (set to 200)|
|VALUEVERIFYMED	|uint256|	Medium amount for loan verification (set to 200)|
|VALUEVERIFYMAX	|uint256|	Maximum amount for loan verification (set to 500)|

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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

### Source Environment
```shell
source .env
```

### Deploy

```shell
$ forge script script/Deploy.s.sol:DeployScript  --rpc-url <your_rpc_url> --private-key <your_private_key>
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
