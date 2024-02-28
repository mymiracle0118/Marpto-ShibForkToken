// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {ShibFork} from "src/ShibFork.sol";
import "test/IWETH.sol";

contract ShibForkTest is Test {
    ShibFork public shib;

    address alice = address(1);
    address bob = address(2);
    address tokenOwner = address(3);

    uint256 bscfork;
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address factoryAddress = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address poolAddress = 0xd0604cb5797Db2Eda79B82d13586F1eDd9de65a3;

    address pool;
    function setUp() public {
        bscfork = vm.createFork(vm.envString("BSC_RPC_URL"));

        vm.selectFork(bscfork);
        assertEq(vm.activeFork(), bscfork);

        vm.rollFork(36534053);

        shib = new ShibFork(tokenOwner);
    }

    function test_buy_fee() public {

        test_createAndAddLiquidity();

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        address[] memory path = new address[](2);
        path[0] = wbnbAddress;
        path[1] = address(shib);

        vm.deal(alice, 5 ether);

        vm.prank(tokenOwner);
        shib.setDex(poolAddress, true);

        vm.prank(alice);
        // (bool success,) =
        // Make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: 1 ether }(
            0, // Accept any amount of tokens
            path,
            address(alice), // Send the tokens to this contract
            block.timestamp + 300 // Set a deadline for the swap
        );

        vm.prank(alice);
        // (bool success,) =
        // Make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: 1 ether }(
            0, // Accept any amount of tokens
            path,
            address(alice), // Send the tokens to this contract
            block.timestamp + 300 // Set a deadline for the swap
        );

        assertEq(shib.feeReceiver(), tokenOwner);
        assertLt(shib.balanceOf(alice), 1 ether);
        assertGt(shib.balanceOf(shib.feeReceiver()), 0);
    }

    function test_sell_sellfee() external {

        test_createAndAddLiquidity();

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        vm.prank(tokenOwner);
        shib.setDex(poolAddress, true);

        vm.prank(tokenOwner);
        shib.mint(alice, 10 ether);

        vm.prank(alice);
        // Approve the router to spend the tokens
        shib.approve(address(router), 1 ether);


        // Path is defined as [token address, WBNB address]
        address[] memory path = new address[](2);
        path[0] = address(shib);
        path[1] = wbnbAddress;

        vm.prank(alice);
        // Swap the tokens
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1 ether,
            1, // AmountOutMinimum
            path,
            address(alice),
            block.timestamp + 15
        );

        assertEq(shib.feeReceiver(), tokenOwner);
        assertGt(address(alice).balance, 0);
        assertGt(shib.balanceOf(shib.feeReceiver()), 0);
    }

    function test_buy_whitelist() public {

        test_createAndAddLiquidity();

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        address[] memory path = new address[](2);
        path[0] = wbnbAddress;
        path[1] = address(shib);

        vm.deal(alice, 5 ether);

        vm.prank(tokenOwner);
        shib.setDex(poolAddress, true);

        vm.prank(tokenOwner);
        shib.setWhiteList(alice, true);

        vm.prank(alice);
        // (bool success,) =
        // Make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: 1 ether }(
            0, // Accept any amount of tokens
            path,
            address(alice), // Send the tokens to this contract
            block.timestamp + 300 // Set a deadline for the swap
        );
        assertEq(shib.feeReceiver(), tokenOwner);
        assertLt(shib.balanceOf(alice), 1 ether);
        assertEq(shib.balanceOf(shib.feeReceiver()), 0);
    }

    function test_sell_whitelist() external {

        test_createAndAddLiquidity();

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        vm.prank(tokenOwner);
        shib.setDex(poolAddress, true);

        vm.prank(tokenOwner);
        shib.mint(alice, 10 ether);

        vm.prank(tokenOwner);
        shib.setWhiteList(alice, true);

        vm.prank(alice);
        // Approve the router to spend the tokens
        shib.approve(address(router), 1 ether);


        // Path is defined as [token address, WBNB address]
        address[] memory path = new address[](2);
        path[0] = address(shib);
        path[1] = wbnbAddress;

        vm.prank(alice);
        // Swap the tokens
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1 ether,
            1, // AmountOutMinimum
            path,
            address(alice),
            block.timestamp + 15
        );

        assertEq(shib.feeReceiver(), tokenOwner);
        assertGt(address(alice).balance, 0);
        assertEq(shib.balanceOf(shib.feeReceiver()), 0);
    }

    function test_createAndAddLiquidity() public {
        // Create the pair if it hasn't been initialized yet.
        pool = IUniswapV2Factory(factoryAddress).createPair(address(shib), wbnbAddress);

        vm.deal(alice, 10 ether);

        vm.prank(alice);
        (bool success,) =
            wbnbAddress.call{ value: 10 ether }(abi.encodeWithSignature("deposit(address,uint256)", alice, 10 ether));
        if (!success) return;

        vm.prank(tokenOwner);
        shib.mint(address(alice), 10 ether);

        vm.prank(alice);
        shib.approve(address(routerAddress), 10 ether);

        vm.startPrank(alice);
        IWETH(wbnbAddress).approve(address(routerAddress), 10 ether);
        shib.approve(address(routerAddress), 10 ether);
        vm.stopPrank();

        vm.prank(alice);
        // Add liquidity to the Uniswap V2 pair
        IUniswapV2Router02(routerAddress).addLiquidity(
            address(shib), wbnbAddress, 10 ether, 10 ether, 9 ether, 9 ether, alice, block.timestamp
        );
    }
}
