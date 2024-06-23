// SPDX-License-Identifier: MIT
pragma solidity >0.8.20;

import "lib/forge-std/src/Script.sol";
import "../src/Borrow.sol";
import "lib/forge-std/src/console.sol";

contract Deploy is Script {
    function run() public {
        Borrow borrow = new Borrow();
        console.log("Borrow address: ", address(borrow));
    }
}

