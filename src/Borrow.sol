// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {

    constructor()
        ERC20("MyToken", "HJK")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

error Staking__TransferFailed();
error Withdraw__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Stake { 
    MyToken private mytoken;

    constructor(address tokenAddress) {
        mytoken = MyToken(tokenAddress);
    }

    mapping(address => uint) public stakers;
    uint public totalSupplyStaked;
    // rastreio de tempo
    mapping(address => uint) internal lastUpdateTime;
    // rastreio de acumulação do token
    mapping(address => uint) public rewardAcumulatedPerUser;
    uint public constant rewardRate = 2; // taxa de 2%
    uint public constant rewardPeriod = 30; // ganho a cada 30s

    event ApprovalStake(address approver, address spender, uint amount);

    modifier updateData(address staker) {
        uint reward = policyRewardsperToken(staker);
        rewardAcumulatedPerUser[staker] += reward;
        lastUpdateTime[staker] = block.timestamp;
        _;
    }

    function getInstanceToken() public view returns(MyToken) {
        return mytoken;
    }
    
    // stake
    function stake(uint256 _amount) external updateData(msg.sender) {
        require(_amount > 0, "Staking: Amount must be greater than zero");

        // Transfer tokens from user to contract
        bool success = mytoken.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert Staking__TransferFailed(); 
        }

        stakers[msg.sender] += _amount;
        totalSupplyStaked += _amount;

        emit ApprovalStake(msg.sender, address(this), _amount);
    }

    // unstaked
    function unstaked(uint _amount) external updateData(msg.sender) {
        require(stakers[msg.sender] >= _amount, "Withdraw__TransferFailed");

        stakers[msg.sender] -= _amount;
        totalSupplyStaked -= _amount;

        // Transfer tokens from contract to user
        mytoken.transfer(msg.sender, _amount);
    }

    // policy rewards
    function policyRewardsperToken(address staker) public view returns(uint) {
        if (stakers[staker] == 0) {
            return 0;
        } else {
            uint currentBalance = stakers[staker]; 
            uint timeStaked = block.timestamp - lastUpdateTime[staker]; // tempo em stake

            uint totalReward = (currentBalance * rewardRate / 100) * (timeStaked / rewardPeriod);

            return totalReward;
        } 
    }

    // claimRewards
    function claimRewards() external updateData(msg.sender) {
        uint reward = rewardAcumulatedPerUser[msg.sender];
        require(reward > 0, "No rewards available");

        mytoken.mint(address(this), reward);
        rewardAcumulatedPerUser[msg.sender] = 0;
        mytoken.transfer(msg.sender, reward);
    }

    // All rewards for withdraw
    // function totalWithdrawPerUser() external view returns(uint) {
    //     return policyRewardsperToken(msg.sender) + rewardAcumulatedPerUser[msg.sender];
    // }
}


// Contrato Borrow terá uma quantidade específica de tokens para oferecer empréstimos
// Terá que pagar os juros de acordo com valor pego e quanto tempo de empréstimo
// O token seguirá o padrão ERC-20

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
    enum LoanStatus{PaidOut, NotPay}

    // i[0] => PaymentLate, i[1] => BadConduct, i[2] => Others
    enum ReasonDeny{PaymentLate, BadConduct, Others}

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
    event usersMakeLoan(address addressUser,uint256 amount,uint256 initialDate,uint256 finalDate);
    event usersPaidOut(address addressUser, uint amount, uint datePaidOut);
    uint256 internal constant VALUEVERIFYMIN = 200;
    uint256 internal constant VALUEVERIFYMED = 200;
    uint256 internal constant VALUEVERIFYMAX = 500;

    //verify the assurance for stake
    // function verifyAssurance() public view returns (uint256) {
    //     if (stakeInstance.stakers(msg.sender) == 0) {
    //         revert("Necessary stake for assurance");
    //     } else if (stakeInstance.stakers(msg.sender) >= 1 && stakeInstance.stakers(msg.sender) <= 2000) {
    //         return VALUEVERIFYMIN;
    //     } else if (stakeInstance.stakers(msg.sender) >= 2001 && stakeInstance.stakers(msg.sender) <= 5000) {
    //         return VALUEVERIFYMED;
    //     }

    //     return VALUEVERIFYMAX;
    // }

    function depositTokens(uint256 _amount) external onlyOwner {
        myToken.transferFrom(msg.sender, address(this), _amount);
    }

    function makeLoan(uint256 _valueLoan, uint256 period) public {
        // constraint
        require(stakeInstance.stakers(msg.sender) > 0, "Necessary stake for assurance");
        require(!userLoans[msg.sender].activate, "You have a loan activate");
        require(userDeny[msg.sender] == false, "Dont have permission for loan");
        require(period >= 5, "The minumum period should be 5");
        require(myToken.balanceOf(address(this)) >= _valueLoan, "Insufficient contract balance");


        myToken.transfer(msg.sender, _valueLoan);


        if (period >= 5 && period <= 20) {
            userLoans[msg.sender].fees = 5;
        } else {
            userLoans[msg.sender].fees = 3;
        }


        userLoans[msg.sender].valueLoan = _valueLoan;
        userLoans[msg.sender].initialDateAgreement = block.timestamp;
        userLoans[msg.sender].finalDateAgreement = userLoans[msg.sender].initialDateAgreement + period * 1 days;
        userLoans[msg.sender].valueFees = userLoans[msg.sender].valueLoan + 
        ((userLoans[msg.sender].valueLoan * userLoans[msg.sender].fees) / 100);
        userLoans[msg.sender].activate = true;
        userLoans[msg.sender].status = LoanStatus.NotPay;

        emit usersMakeLoan(
            msg.sender,
            _valueLoan,
            block.timestamp,
            block.timestamp + period
        );
    }

    // deny the user for make loan
    function denyUser(address _denyUser, ReasonDeny reason) public onlyOwner
    {                         
        require(userDeny[_denyUser] = false, "User is already denied");
        userDeny[_denyUser] = true;
        userLoans[_denyUser].activate = false;
        myToken.transferFrom(_denyUser, address(this), userLoans[_denyUser].valueLoan);
        userLoans[_denyUser].valueLoan = 0;
        emit usersDenyEvent(_denyUser, reason);
    }

    //payment the loan
    function paymentLoan(uint amount) public {
        require(userLoans[msg.sender].activate, "You not have a loan activate");
        require(myToken.balanceOf(msg.sender) >= userLoans[msg.sender].valueFees, "Insufficient balance");
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

    // verify balance loan
    function getBalanceLoan() public view returns (uint256) {
        return userLoans[msg.sender].valueFees;
    }

    function getBalanceContract() public view returns (uint) {
        return myToken.balanceOf(address(this));
    }
}
