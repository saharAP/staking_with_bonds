// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staker} from "../src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IWETH{
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

contract StakerForkTest is Test {
    address public user1;
    address public user2;
    Staker public staker;
    address public owner;

    // staking tokens;
    IWETH public weth;
    IERC20 public usdc;
    
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    function setUp() public {
        user1 = 0x55FE002aefF02F77364de339a1292923A15844B8; //Whale address
        user2= 0x5939F00372B62877D9F46f5AB9881402D8006377;
        staker = new Staker();
        owner = address(this);
        // Set up WETH
        weth = IWETH(WETH_ADDRESS);
        // Set up USDC
        usdc = IERC20(USDC_ADDRESS);
      
        // Whitelist the staking token
        staker.updateTokenWhitelistStatus(WETH_ADDRESS, true);
        staker.updateTokenWhitelistStatus(USDC_ADDRESS, true);
       // transfer some weth token to user1
        weth.deposit{value:100000 * 10**18}();
        weth.transfer(user1, 10000 * 10**18);
    
        vm.startPrank(user1);
        weth.approve(address(staker), type(uint256).max);
        usdc.approve(address(staker), type(uint256).max);
        vm.stopPrank();
    }
    function testDeposit() public {
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, 100 * 10**18, staker.ONE_WEEK_NOTICE());
         vm.stopPrank();
        assertEq(  staker.st1wToken().balanceOf(user1), 100 * 10**18);
        assertEq(staker.balanceOf(WETH_ADDRESS, user1), 100 * 10**18);
        
    }
    function testDepositWithDifferentNoticePeriods() public {
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, 600 * 10**18, staker.ONE_WEEK_NOTICE());
        staker.deposit(WETH_ADDRESS, 400 * 10**18, staker.FOUR_WEEK_NOTICE());
        vm.stopPrank();
      
        assertEq(  staker.st1wToken().balanceOf(user1), 600 * 10**18);
        assertEq(  staker.st4wToken().balanceOf(user1), 400 * 10**18);
        assertEq(staker.balanceOf(WETH_ADDRESS, user1), 1000 * 10**18);
    }
    function testRequestWithdraw() public {
        vm.startPrank(user1);
        uint256 deposit_amount= 100 * 10**18;
        staker.deposit(WETH_ADDRESS, deposit_amount, staker.ONE_WEEK_NOTICE());
        
        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount= 20 * 10**18;
        staker.requestWithdraw(WETH_ADDRESS, withdraw_amount, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        uint256 remaining= deposit_amount-withdraw_amount;
        assertEq(staker.balanceOf(WETH_ADDRESS, user1),remaining);
       
 
        (,,,,uint256 withdrawalAmount,,bool requestedWithdrawal) = staker.stakeDetails(WETH_ADDRESS, user1);
        assertTrue(requestedWithdrawal, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount, withdraw_amount, "Withdrawal amount should match requested amount");
    }
    function testMultipleRequestWithdrawForMultipleTokens() public {
        vm.startPrank(user1);
        uint256 deposit_amount_weth= 100 * 10**18;
        staker.deposit(WETH_ADDRESS, deposit_amount_weth, staker.ONE_WEEK_NOTICE());
        
        uint256 deposit_amount_usdc= 200 * 10**6;
        staker.deposit(USDC_ADDRESS, deposit_amount_usdc, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount_weth= 20 * 10**18;
        staker.requestWithdraw(WETH_ADDRESS, withdraw_amount_weth, staker.ONE_WEEK_NOTICE());
        
        uint256 withdraw_amount_usdc= 40 * 10**6;
        staker.requestWithdraw(USDC_ADDRESS, withdraw_amount_usdc, staker.ONE_WEEK_NOTICE());
        vm.stopPrank();
        uint256 remaining_weth= deposit_amount_weth-withdraw_amount_weth;
        assertEq(staker.balanceOf(WETH_ADDRESS, user1),remaining_weth);

        uint256 remaining_usdc= deposit_amount_usdc-withdraw_amount_usdc;
        assertEq(staker.balanceOf(USDC_ADDRESS, user1),remaining_usdc);

        (,,,,uint256 withdrawalAmount_weth,,bool requestedWithdrawal_weth) = staker.stakeDetails(WETH_ADDRESS, user1);
        assertTrue(requestedWithdrawal_weth, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount_weth, withdraw_amount_weth, "Withdrawal amount should match requested amount");

        (,,,,uint256 withdrawalAmount_usdc,,bool requestedWithdrawal_usdc) = staker.stakeDetails(USDC_ADDRESS, user1);
        assertTrue(requestedWithdrawal_usdc, "requestedWithdrawal should be true after requesting withdrawal");
        assertEq(withdrawalAmount_usdc, withdraw_amount_usdc, "Withdrawal amount should match requested amount");
    }
    function testClaim() public {
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, 1000 * 10**18, staker.FOUR_WEEK_NOTICE());
        
         // Fast forward time
        vm.warp(block.timestamp + 100 days);

        vm.stopPrank();
        
        vm.startPrank(user1);
        uint256 withdraw_amount= 500 * 10**18;
        staker.requestWithdraw(WETH_ADDRESS, 500 * 10**18, staker.FOUR_WEEK_NOTICE());
        
        // Fast forward time
        vm.warp(block.timestamp + staker.FOUR_WEEK_NOTICE() + 1);
        
        vm.stopPrank();
        
        uint256 balanceBefore = weth.balanceOf(user1);
        
        vm.startPrank(user1);
        staker.claim(WETH_ADDRESS);
        vm.stopPrank();

        uint256 balanceAfter = weth.balanceOf(user1);
        assertGt(balanceAfter, balanceBefore+withdraw_amount,  "User1 blance of weth should be increased");
        (, , , uint256 yield,
            uint256 withdrawalAmount,,
            bool requestedWithdrawal
        ) = staker.stakeDetails(WETH_ADDRESS, user1);
        assertEq(yield, 0, "User1 yield from token1 should be zero");
        assertEq(withdrawalAmount, 0, "User1 requested withdrawal amount for token1 should be zero");
        assertEq(requestedWithdrawal, false, "User1 requestedWithdrawal for token1 should be false");    
    }
    function testAdminYieldDeposit() public {
        vm.startPrank(owner);
        weth.approve(address(staker), 1000 * 10**18);
        staker.adminYieldDeposit(WETH_ADDRESS, 1000 * 10**18);

        vm.stopPrank();
        
        assertEq(weth.balanceOf(address(staker)), 1000 * 10**18);
    }
    function testUpdateTokenWhitelistStatus() public {
        address DAI_ADDRESS =0x6B175474E89094C44Da98b954EedeAC495271d0F;
        vm.startPrank(owner);
        staker.updateTokenWhitelistStatus(DAI_ADDRESS, true);
        assertTrue(staker.isTokenWhitelisted(DAI_ADDRESS));

        staker.updateTokenWhitelistStatus(DAI_ADDRESS, false);

        vm.stopPrank();
        
        assertFalse(staker.isTokenWhitelisted(DAI_ADDRESS));
    }
    
    function testYieldComputation() public {
        uint256 depositAmount = 1000 * 10**18;
        uint256 stakingDuration = 30 days;

        // User deposits tokens
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, depositAmount, staker.ONE_WEEK_NOTICE());
  
        // Fast forward time
        vm.warp(block.timestamp + stakingDuration);

        // Calculate expected yield
        uint256 expectedYield = calculateExpectedYield(depositAmount, stakingDuration);
        // Request withdrawal to trigger yield calculation
        staker.requestWithdraw(WETH_ADDRESS, depositAmount, staker.ONE_WEEK_NOTICE());
        
        vm.stopPrank();
        
        // Get the actual yield
        (,,,uint256 actualYield,,,) = staker.stakeDetails(WETH_ADDRESS, user1);
        // Assert that the actual yield matches the expected yield
        assertEq(actualYield, expectedYield, "Yield computation mismatch");
    }
    function testTransferStakeTokens() public{
        uint256 depositAmount = 1000 * 10**18;
        // User deposits tokens
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, depositAmount, staker.ONE_WEEK_NOTICE());
        uint256 transfer_amount= 100 * 10**18;
        staker.st1wToken().transfer(user2, transfer_amount);
        assertEq( staker.st1wToken().balanceOf(user2), transfer_amount);
    }
    function calculateExpectedYield(uint256 amount, uint256 duration) internal view returns (uint256) {
        // This should match the yield calculation in your Staker contract
        uint256 annualRate = staker.INTEREST_RATE();
        uint256 yearInSeconds = 365 days;
        return (amount * annualRate * duration) / (100 * yearInSeconds);
    }
}