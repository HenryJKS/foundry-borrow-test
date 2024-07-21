// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/MyToken.sol";

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
    // tracking time
    mapping(address => uint) internal lastUpdateTime;
    // tracking token accumulation
    mapping(address => uint) public rewardAcumulatedPerUser;
    uint public constant rewardRate = 2; // 2% rate
    uint public constant rewardPeriod = 30; // gain every 30s

    event ApprovalStake(address approver, address spender, uint amount);

    modifier updateData(address staker) {
        uint reward = policyRewardsperToken(staker);
        rewardAcumulatedPerUser[staker] += reward;
        lastUpdateTime[staker] = block.timestamp;
        _;
    }

    function getInstanceToken() public view returns (MyToken) {
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

    // unstake
    function unstake(uint _amount) external updateData(msg.sender) {
        require(stakers[msg.sender] >= _amount, "Withdraw__TransferFailed");

        stakers[msg.sender] -= _amount;
        totalSupplyStaked -= _amount;

        // Transfer tokens from contract to user
        mytoken.transfer(msg.sender, _amount);
    }

    // policy rewards
    function policyRewardsperToken(address staker) public view returns (uint) {
        if (stakers[staker] == 0) {
            return 0;
        } else {
            uint currentBalance = stakers[staker];
            uint timeStaked = block.timestamp - lastUpdateTime[staker]; // time staked

            uint totalReward = ((currentBalance * rewardRate) / 100) *
                (timeStaked / rewardPeriod);

            return totalReward;
        }
    }

    // claim rewards
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