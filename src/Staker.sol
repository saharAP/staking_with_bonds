// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/St1wToken.sol";
import "./tokens/St4wToken.sol";

contract Staker is Pausable, Ownable {
   using SafeERC20 for IERC20;

    St1wToken public immutable st1wToken;      // ERC-20 token for 1-week notice
    St4wToken public immutable st4wToken;      // ERC-20 token for 4-week notice

    uint256 public constant INTEREST_RATE = 5;  // 5% interest rate
    uint256 public constant ONE_WEEK_NOTICE= 1 weeks;
    uint256 public constant FOUR_WEEK_NOTICE= 4 weeks;
    
    // Mapping to keep track of whitelisted staking tokens
    mapping(address => bool) public whitelist;

    struct Stake{
        uint256 amount;
        uint256 startTime;
        uint256 noticePeriod;
        uint256 yield;
        uint256 WithdrawalAmount;
        uint256 requestedWithdrawalTime;
        bool requestedWithdrawal;
    }
    // Mapping to keep track of stakes for each user
    mapping(address => mapping(address => Stake)) public users;

    event Staked(address indexed user,address stakingToken, uint256 amount, uint256 noticePeriod);
    event TokenWhitelistStatusUpdated(address indexed token, bool updated);
    event WithdrawalRequested(address indexed user,  address token, uint256 amount, uint256 noticePeriod);
    event YieldDeposited(address indexed token, uint256 amount);
    event claimed(address indexed user, address token, uint256 amount);
    constructor()Ownable(msg.sender){
     st1wToken = new St1wToken();
     st4wToken = new St4wToken();
    }
    //******** Public functions ***********//
    function deposit(address stakingToken,uint256 amount, uint256 noticePeriod) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(whitelist[stakingToken], "Token is not whitelisted");
       
           
        Stake storage stake= users[msg.sender][stakingToken];
        uint256 stake_amount= stake.amount;
        if(stake_amount > 0){
            stake.yield+= calculateYield(stake_amount, stake.startTime);
        }

        stake.amount+= amount;
        stake.startTime= block.timestamp;

        IERC20 token= IERC20(stakingToken);
        token.safeTransferFrom(msg.sender, address(this), amount);
        if (noticePeriod == ONE_WEEK_NOTICE) {
            st1wToken.mint(msg.sender, amount);
        } else if (noticePeriod == FOUR_WEEK_NOTICE) {
            st4wToken.mint(msg.sender, amount);
        }
        else{revert("Invalid notice period");}

        emit Staked(msg.sender, stakingToken, amount, noticePeriod);
    }
    function requestWithdraw(address stakingToken, uint256 amount, uint256 noticePeriod) external whenNotPaused{
        Stake storage stake= users[msg.sender][stakingToken];
        require(amount > 0, "Amount must be greater than 0"); 
        require(stake.amount >= amount , "Insufficient balance");
        require(!stake.requestedWithdrawal, "Withdrawal already requested");

        stake.requestedWithdrawal=true;
        stake.requestedWithdrawalTime=block.timestamp;

        if (noticePeriod == ONE_WEEK_NOTICE) {
            st1wToken.burn(msg.sender, amount);
        } else if (noticePeriod == FOUR_WEEK_NOTICE) {
            st4wToken.burn(msg.sender, amount);
        }
        uint256 yield=calculateYield(stake.amount, stake.startTime);
        stake.noticePeriod= noticePeriod;
        stake.startTime=block.timestamp;
        stake.amount -= amount;
        stake.yield+= yield;
        stake.WithdrawalAmount= amount;

        emit WithdrawalRequested(msg.sender, stakingToken, amount, noticePeriod);
    }
    function claim(address stakingToken) external whenNotPaused {
        Stake storage stake= users[msg.sender][stakingToken];
        require(stake.requestedWithdrawal, "No withdrawal requested");
        require(block.timestamp >= stake.requestedWithdrawalTime+stake.noticePeriod, "Notice period not yet over");
        uint256 claim_amount= stake.WithdrawalAmount + stake.yield;
        IERC20(stakingToken).safeTransfer(msg.sender, claim_amount);
        
        stake.WithdrawalAmount  = 0;
        stake.yield = 0;
        stake.requestedWithdrawal = false;
        emit claimed(msg.sender, stakingToken, claim_amount);
    }
//******** Owner functions ***********//
     function adminYieldDeposit(address stakingToken, uint256 amount) external onlyOwner {
        require(whitelist[stakingToken], "Token is not whitelisted");
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        
        emit YieldDeposited(stakingToken, amount);
    }
    function updateTokenWhitelistStatus(address token, bool status) public onlyOwner {
        whitelist[token] = status;

        emit TokenWhitelistStatusUpdated(token, status);
    }
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
   //******** View functions ***********//

    function calculateYield(uint256 amount, uint256 startTime) internal view returns (uint256) {
        uint256 stakingDuration = block.timestamp - startTime;
        uint256 yield = (amount * INTEREST_RATE * stakingDuration) / (100 * 365 days);
        return yield;
    }
    function stakeDetails(address stakingToken, address account) external view returns(
            uint256 amount,
            uint256 startTime,
            uint256 noticePeriod,
            uint256 yield,
            uint256 withdrawalAmount,
            uint256 requestedWithdrawalTime,
            bool requestedWithdrawal
        ){
        Stake memory stake=users[account][stakingToken];
        return(
            stake.amount,
            stake.startTime,
            stake.noticePeriod,
            stake.yield,
            stake.WithdrawalAmount,
            stake.requestedWithdrawalTime,
            stake.requestedWithdrawal
        );
    }
    function balanceOf(address stakingToken, address account) external view returns (uint256) {
        return users[account][stakingToken].amount;
    }
    function isTokenWhitelisted(address token) public view returns (bool) {
        return whitelist[token];
    }
}