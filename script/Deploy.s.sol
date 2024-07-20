// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Script.sol";
import "../src/Borrow.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy MyToken contract
        MyToken myToken = new MyToken(msg.sender);

        // Deploy Stake contract
        Stake stake = new Stake(address(myToken));

        // Deploy Borrow contract
        Borrow borrow = new Borrow(address(stake));

        vm.stopBroadcast();

        // Log the addresses of the deployed contracts
        console.log("MyToken address:", address(myToken));
        console.log("Stake address:", address(stake));
        console.log("Borrow address:", address(borrow));
    }
}
