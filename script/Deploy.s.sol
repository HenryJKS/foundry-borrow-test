// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Borrow.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy MyToken contract
        MyToken myToken = new MyToken();

        // Deploy Stake contract with MyToken address
        Stake stake = new Stake(address(myToken));

        vm.stopBroadcast();

        // Log the addresses of the deployed contracts
        console.log("MyToken address:", address(myToken));
        console.log("Stake address:", address(stake));
    }
}
