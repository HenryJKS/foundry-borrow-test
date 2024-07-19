// SPDX-License-Identifier: MIT
pragma solidity >0.8.20;

import "lib/forge-std/src/Test.sol";
import "../src/Borrow.sol";

contract BorrowTest is Test {
    Borrow borrow;

    function setUp() public {
        borrow = new Borrow();
    }

    function testSymbol() public view {
        assertEq(borrow.symbol(), "HJK");
    }

    function BalanceOfOwnerIs1000() public view {
        assertEq(borrow.balanceOf(msg.sender), 1000);
        
    }
}