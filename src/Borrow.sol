// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/MyToken.sol";
import "src/Stake.sol";

// The Borrow contract will have a specific amount of tokens to offer loans
// It will have to pay interest according to the value taken and the loan duration
// The token will follow the ERC-20 standard

contract Borrow {
    Stake private stakeInstance;
    MyToken private myToken;

    constructor(address addrStake) {
        stakeInstance = Stake(addrStake);
        myToken = MyToken(stakeInstance.getInstanceToken());
    }

    modifier onlyOwner() {
        require(msg.sender == myToken.owner(), "only owner");
        _;
    }

    // i[0] => PaidOut, i[1] => NotPay
    enum LoanStatus {
        PaidOut,
        NotPay
    }

    // i[0] => PaymentLate, i[1] => BadConduct, i[2] => Others
    enum ReasonDeny {
        PaymentLate,
        BadConduct,
        Others
    }

    struct Loans {
        uint256 valueLoan;
        uint256 initialDateAgreement;
        uint256 finalDateAgreement;
        uint256 fees;
        uint256 valueFees;
        bool activate;
        LoanStatus status;
    }

    mapping(address => Loans) public userLoans;
    mapping(address => bool) public userDeny;
    event usersDenyEvent(address addressDeny, ReasonDeny rd);
    event usersMakeLoan(
        address addressUser,
        uint256 amount,
        uint256 initialDate,
        uint256 finalDate
    );
    event usersPaidOut(address addressUser, uint amount, uint datePaidOut);
    uint256 internal constant VALUEVERIFYMIN = 200;
    uint256 internal constant VALUEVERIFYMED = 200;
    uint256 internal constant VALUEVERIFYMAX = 500;

    // verify the assurance for stake
    function verifyAssurance() public view returns (bool) {
        if (stakeInstance.stakers(msg.sender) == 0) {
            return false;
        }

        return true;
    }

    function depositTokens(uint256 _amount) external onlyOwner {
        myToken.transferFrom(msg.sender, address(this), _amount);
    }

    function makeLoan(uint256 _valueLoan, uint256 period) public {
        // constraint
        require(verifyAssurance() == true, "Need the stake for assurance");
        require(!userLoans[msg.sender].activate, "You have a loan activate");
        require(userDeny[msg.sender] == false, "Dont have permission for loan");
        require(period >= 5, "The minimum period should be 5");
        require(
            myToken.balanceOf(address(this)) >= _valueLoan,
            "Insufficient contract balance"
        );

        myToken.transfer(msg.sender, _valueLoan);

        if (period >= 5 && period <= 20) {
            userLoans[msg.sender].fees = 5;
        } else {
            userLoans[msg.sender].fees = 3;
        }

        userLoans[msg.sender].valueLoan = _valueLoan;
        userLoans[msg.sender].initialDateAgreement = block.timestamp;
        userLoans[msg.sender].finalDateAgreement =
            userLoans[msg.sender].initialDateAgreement +
            period *
            1 days;
        userLoans[msg.sender].valueFees =
            userLoans[msg.sender].valueLoan +
            ((userLoans[msg.sender].valueLoan * userLoans[msg.sender].fees) /
                100);
        userLoans[msg.sender].activate = true;
        userLoans[msg.sender].status = LoanStatus.NotPay;

        emit usersMakeLoan(
            msg.sender,
            _valueLoan,
            block.timestamp,
            block.timestamp + period
        );
    }

    // deny the user for making loan
    function denyUser(address _denyUser, ReasonDeny reason) public onlyOwner {
        require(userDeny[_denyUser] == false, "User is already denied");
        userDeny[_denyUser] = true;
        userLoans[_denyUser].activate = false;
        myToken.transferFrom(
            _denyUser,
            address(this),
            userLoans[_denyUser].valueLoan
        );
        userLoans[_denyUser].valueLoan = 0;
        emit usersDenyEvent(_denyUser, reason);
    }

    // payment of the loan
    function paymentLoan(uint amount) public {
        require(
            userLoans[msg.sender].activate,
            "You do not have an active loan"
        );
        require(
            myToken.balanceOf(msg.sender) >= userLoans[msg.sender].valueFees,
            "Insufficient balance"
        );
        require(userLoans[msg.sender].valueFees <= amount, "Necessary payment");

        myToken.transferFrom(msg.sender, address(this), amount);

        if (userLoans[msg.sender].valueFees == amount) {
            userLoans[msg.sender].valueFees = 0;
            userLoans[msg.sender].activate = false;
            userLoans[msg.sender].status = LoanStatus.PaidOut;
            emit usersPaidOut(msg.sender, amount, block.timestamp);
        } else {
            userLoans[msg.sender].valueFees -= amount;
        }
    }

    function getBalanceContract() public view returns (uint) {
        return myToken.balanceOf(address(this));
    }

    // Getting info per user
    function getBalanceLoan() public view returns (uint256) {
        return userLoans[msg.sender].valueLoan;
    }

    function getTotalPayment() public view returns(uint) {
        return userLoans[msg.sender].valueFees;
    }

    function returnStatus() public view returns(uint) {
        return uint(userLoans[msg.sender].status);
    }

}

// update the denyUser() for when the user not pay your loan, block and withdraw the amount in loan.
