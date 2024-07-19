// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import "../src/Borrow.sol";

contract BorrowTest is Test {
    MyToken myToken;
    Stake stake;
    Borrow borrow;

    function setUp() public {
        myToken = new MyToken();

        stake = new Stake(address(myToken));

        borrow = new Borrow(address(stake));
    }

    function testMyToken() public {
        // verify the totalSupply
        assertEq(
            myToken.totalSupply(),
            1000 * 10 ** myToken.decimals()
        );

        // verify the balanceof the owner
        assertEq(
            myToken.balanceOf(myToken.owner()),
            1000 * 10 ** myToken.decimals()
        );
    }

    function testStake() public {
        
    }
}
