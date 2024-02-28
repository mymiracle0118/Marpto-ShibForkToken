// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";
import "src/ShibaPork.sol";

contract ShibaPorkScript is Script {

    ShibaPork shiba;
    function setUp() public {}

    function run() external {
        // Anything within the broadcast cheatcodes is executed on-chain
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("TOKEN_OWNER");

        vm.startBroadcast(deployerPrivateKey);

        shiba = new ShibaPork(owner);

        vm.stopBroadcast();
    }
}
