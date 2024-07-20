// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Test.sol";
import "../src/Borrow.sol";

contract BorrowTest is Test {
    MyToken myToken;
    Stake stake;
    Borrow borrow;
    address user1 = address(0x1);
    address owner = address(0x2);

    function setUp() public {
        myToken = new MyToken(address(owner));

        stake = new Stake(address(myToken));

        borrow = new Borrow(address(stake));

        // Verifique os saldos iniciais
        assertEq(
            myToken.balanceOf(owner),
            1000 * 10 ** myToken.decimals(),
            "Owner should have initial tokens"
        );
    }

    function testTotalSupplyIs1000() public view {
        // verify the totalSupply
        assertEq(myToken.totalSupply(), 1000 * 10 ** myToken.decimals());
    }

    function testBalanceOfOwner() public view {
        // verify the balanceof the owner
        assertEq(
            myToken.balanceOf(myToken.owner()),
            1000 * 10 ** myToken.decimals()
        );
    }

    function testTransfer() public {
        vm.prank(myToken.owner());
        myToken.transfer(user1, 1000);
        assertEq(myToken.balanceOf(user1), 1000);
    }

    function testStake() public {
        // stake 1000 tokens
        vm.prank(myToken.owner());
        myToken.transfer(user1, 1000);

        vm.prank(user1);
        myToken.approve(address(stake), 1000);

        vm.prank(user1);
        stake.stake(1000);

        // verify the stakers mapping
        assertEq(stake.stakers(user1), 1000);
    }

    function testUnstake() public {
        vm.prank(myToken.owner());
        myToken.transfer(user1, 1000);

        vm.prank(user1);
        myToken.approve(address(stake), 1000);

        vm.prank(user1);
        stake.stake(1000);

        vm.prank(user1);
        stake.unstake(1000);
        assertEq(stake.stakers(user1), 0);
    }

    function testBorrow() public {
        vm.prank(myToken.owner());
        myToken.transfer(user1, 1000);

        vm.prank(user1);
        myToken.approve(address(stake), 1000);

        vm.prank(user1);
        stake.stake(1000);

        vm.prank(myToken.owner());
        myToken.approve(address(borrow), 50000);

        vm.prank(myToken.owner());
        borrow.depositTokens(50000);

        vm.prank(user1);
        borrow.makeLoan(100, 5);

        vm.prank(user1);
        uint balanceLoanOfUser = borrow.getBalanceLoan();

        assertEq(balanceLoanOfUser, 100);
    }
}
