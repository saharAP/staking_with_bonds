// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staker} from "../src/Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWETH{
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

contract StakerForkTest is Test {
    address public user1;
    Staker public staker;

    // IERC20 public weth;
    IWETH public weth;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        user1 = 0x55FE002aefF02F77364de339a1292923A15844B8;
        staker = new Staker();

        // Set up WETH
        weth = IWETH(WETH_ADDRESS);

      
        // Whitelist the staking token
        staker.updateTokenWhitelistStatus(WETH_ADDRESS, true);
       // transfer some weth token to user1
        weth.deposit{value:100000 * 10**18}();
        weth.transfer(user1, 10000 * 10**18);
        vm.startPrank(user1);
        weth.approve(address(staker), type(uint256).max);
        vm.stopPrank();
    }
    function testDeposit() public {
        vm.startPrank(user1);
        staker.deposit(WETH_ADDRESS, 100 * 10**18, staker.ONE_WEEK_NOTICE());
         vm.stopPrank();
        assertEq(  staker.st1wToken().balanceOf(user1), 100 * 10**18);
        assertEq(staker.balanceOf(WETH_ADDRESS, user1), 100 * 10**18);
        
    }



}