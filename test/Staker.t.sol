// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staker} from "../src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
contract StakerTest is Test {
    Staker public staker;
    
    MockERC20 public stakingToken1;
    MockERC20 public stakingToken2;
    address public owner;
    address public user1;
    address public user2;

    struct Stake{
        uint256 amount;
        uint256 startTime;
        uint256 noticePeriod;
        uint256 yield;
        uint256 WithdrawalAmount;
        uint256 requestedWithdrawalTime;
        bool requestedWithdrawal;
    }
    function setUp() public {
        owner = address(this);
        user1 = address(0x10203047);
        user2 = address(0x2);

        staker = new Staker();
        stakingToken1 = new MockERC20("Mock Token1", "MTK1");
        stakingToken2 = new MockERC20("Mock Token2", "MTK2");
        // // Whitelist the staking token
        staker.updateTokenWhitelistStatus(address(stakingToken1), true);
        staker.updateTokenWhitelistStatus(address(stakingToken2), true);
        // // Transfer some tokens to users
        stakingToken1.transfer(user1, 10000 * 10**18);
        stakingToken2.transfer(user1, 10000 * 10**18);
    }
    function testDeposit() public {
        vm.startPrank(user1);
        stakingToken1.approve(address(staker), 100 * 10**18);
        staker.deposit(address(stakingToken1), 100 * 10**18, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
      
        assertEq(  staker.st1wToken().balanceOf(user1), 100 * 10**18);
        assertEq(staker.balanceOf(address(stakingToken1), user1), 100 * 10**18);
    }
    function testDepositWithDifferentNoticePeriods() public {
        vm.startPrank(user1);
        stakingToken1.approve(address(staker), 1000 * 10**18);
        staker.deposit(address(stakingToken1), 600 * 10**18, staker.ONE_WEEK_NOTICE());
        staker.deposit(address(stakingToken1), 400 * 10**18, staker.FOUR_WEEK_NOTICE());
        vm.stopPrank();
      
        assertEq(  staker.st1wToken().balanceOf(user1), 600 * 10**18);
        assertEq(  staker.st4wToken().balanceOf(user1), 400 * 10**18);
        assertEq(staker.balanceOf(address(stakingToken1), user1), 1000 * 10**18);
    }
    function testRequestWithdraw() public {
        vm.startPrank(user1);
        uint256 deposit_amount= 100 * 10**18;
        stakingToken1.approve(address(staker), deposit_amount);
        staker.deposit(address(stakingToken1), deposit_amount, staker.ONE_WEEK_NOTICE());
        
        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount= 20 * 10**18;
        staker.requestWithdraw(address(stakingToken1), withdraw_amount, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        uint256 remaining= deposit_amount-withdraw_amount;
        assertEq(staker.balanceOf(address(stakingToken1), user1),remaining);
       
 
        (,,,,uint256 withdrawalAmount,,bool requestedWithdrawal) = staker.stakeDetails(address(stakingToken1), user1);
        assertTrue(requestedWithdrawal, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount, withdraw_amount, "Withdrawal amount should match requested amount");
    }
        function testMultipleRequestWithdrawForMultipleTokens() public {
        vm.startPrank(user1);
        uint256 deposit_amount_t1= 100 * 10**18;
        stakingToken1.approve(address(staker), deposit_amount_t1);
        staker.deposit(address(stakingToken1), deposit_amount_t1, staker.ONE_WEEK_NOTICE());
        
        uint256 deposit_amount_t2= 200 * 10**18;
        stakingToken2.approve(address(staker), deposit_amount_t2);
        staker.deposit(address(stakingToken2), deposit_amount_t2, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount_t1= 20 * 10**18;
        staker.requestWithdraw(address(stakingToken1), withdraw_amount_t1, staker.ONE_WEEK_NOTICE());
        
        uint256 withdraw_amount_t2= 40 * 10**18;
        staker.requestWithdraw(address(stakingToken2), withdraw_amount_t2, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        uint256 remaining_t1= deposit_amount_t1-withdraw_amount_t1;
        assertEq(staker.balanceOf(address(stakingToken1), user1),remaining_t1);

        uint256 remaining_t2= deposit_amount_t2-withdraw_amount_t2;
        assertEq(staker.balanceOf(address(stakingToken2), user1),remaining_t2);

        (,,,,uint256 withdrawalAmount_t1,,bool requestedWithdrawal_t1) = staker.stakeDetails(address(stakingToken1), user1);
        assertTrue(requestedWithdrawal_t1, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount_t1, withdraw_amount_t1, "Withdrawal amount should match requested amount");

        (,,,,uint256 withdrawalAmount_t2,,bool requestedWithdrawal_t2) = staker.stakeDetails(address(stakingToken2), user1);
        assertTrue(requestedWithdrawal_t2, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount_t2, withdraw_amount_t2, "Withdrawal amount should match requested amount");
    }
    function testClaim() public {
        vm.startPrank(user1);
        stakingToken1.approve(address(staker), 1000 * 10**18);
        staker.deposit(address(stakingToken1), 1000 * 10**18, staker.FOUR_WEEK_NOTICE());
        
         // Fast forward time
        vm.warp(block.timestamp + 100 days);

        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount= 500 * 10**18;
        staker.requestWithdraw(address(stakingToken1), 500 * 10**18, staker.FOUR_WEEK_NOTICE());
        
        // Fast forward time
        vm.warp(block.timestamp + staker.FOUR_WEEK_NOTICE() + 1);
        
        vm.stopPrank();
        
        uint256 balanceBefore = stakingToken1.balanceOf(user1);
        
        vm.startPrank(user1);
        staker.claim(address(stakingToken1));
        vm.stopPrank();

        uint256 balanceAfter = stakingToken1.balanceOf(user1);
        assertGt(balanceAfter, balanceBefore+withdraw_amount,  "User1 blance of token1 should be increased");
        (, , , uint256 yield,
            uint256 withdrawalAmount,,
            bool requestedWithdrawal
        ) = staker.stakeDetails(address(stakingToken1), user1);
        assertEq(yield, 0, "User1 yield from token1 should be zero");
        assertEq(withdrawalAmount, 0, "User1 requested withdrawal amount for token1 should be zero");
        assertEq(requestedWithdrawal, false, "User1 requestedWithdrawal for token1 should be false");
        
    }
    function testAdminYieldDeposit() public {
        vm.startPrank(owner);
        stakingToken1.approve(address(staker), 1000 * 10**18);
        staker.adminYieldDeposit(address(stakingToken1), 1000 * 10**18);

        vm.stopPrank();
        
        assertEq(stakingToken1.balanceOf(address(staker)), 1000 * 10**18);
    }
    function testUpdateTokenWhitelistStatus() public {
        address newToken = address(0x123);
        vm.startPrank(owner);
        staker.updateTokenWhitelistStatus(newToken, true);
        assertTrue(staker.isTokenWhitelisted(newToken));

        staker.updateTokenWhitelistStatus(newToken, false);

        vm.stopPrank();
        
        assertFalse(staker.isTokenWhitelisted(newToken));
    }
    function testYieldComputation() public {
        uint256 depositAmount = 1000 * 10**18;
        uint256 stakingDuration = 30 days;

        // User deposits tokens
        vm.startPrank(user1);
        stakingToken1.approve(address(staker), depositAmount);
        staker.deposit(address(stakingToken1), depositAmount, staker.ONE_WEEK_NOTICE());
  
        // Fast forward time
        vm.warp(block.timestamp + stakingDuration);

        // Calculate expected yield
        uint256 expectedYield = calculateExpectedYield(depositAmount, stakingDuration);
        // Request withdrawal to trigger yield calculation
        staker.requestWithdraw(address(stakingToken1), depositAmount, staker.ONE_WEEK_NOTICE());
        
        vm.stopPrank();
        
        // Get the actual yield
        (,,,uint256 actualYield,,,) = staker.stakeDetails(address(stakingToken1), user1);
        // Assert that the actual yield matches the expected yield
        assertEq(actualYield, expectedYield, "Yield computation mismatch");
    }

        function calculateExpectedYield(uint256 amount, uint256 duration) internal view returns (uint256) {
        // This should match the yield calculation in your Staker contract
        uint256 annualRate = staker.INTEREST_RATE();
        uint256 yearInSeconds = 365 days;
        return (amount * annualRate * duration) / (100 * yearInSeconds);
    }
}