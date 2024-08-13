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


}