// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ShibaPork is ERC20, Ownable {

    uint256 public feePercent;
    address public feeReceiver;

    uint256 public MAX_SUPPLY;
    uint256 minted;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public dex;
    constructor(address initialOwner)
        ERC20("ShibaPork", "SORK")
        Ownable(initialOwner)
    {
        feeReceiver = initialOwner;
        feePercent = 50;
        MAX_SUPPLY = 581_000_000_000_000_000000000000000000;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(minted + amount <= MAX_SUPPLY, "Overflow total supply");
        minted += amount;
        _mint(to, amount);
    }

    function setFeeReceiver(address to) public onlyOwner {
        require(to != address(0x0), "Non zero address");
        feeReceiver = to;
    }

    function setWhiteList(address to, bool _flag) public onlyOwner {
        whitelist[to] = _flag;
    }

    function setDex(address to, bool _flag) public onlyOwner {
        dex[to] = _flag;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // console.log("transferFrom function");

        // console.log("transfer from address");
        // console.log(from);
        // console.log("transfer to address");
        // console.log(to);

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        // console.log("after allowance");

        uint256 effectiveAmount = amount;
        uint256 feeAmount;
        if (feeAvailable(from, to)) {
            feeAmount = calculateFeeAmount(amount, feePercent);
            // console.log("fee Amount");
            // console.log(feeAmount);
            effectiveAmount = amount - feeAmount;
            _transfer(from, feeReceiver, feeAmount);
        }

        _transfer(from, to, effectiveAmount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        // console.log("transfer fucntion");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance.");
        uint256 effectiveAmount = amount;
        uint256 feeAmount;
        if (feeAvailable(msg.sender, to)) {
            feeAmount = calculateFeeAmount(amount, feePercent);
            // console.log("fee Amount");
            // console.log(feeAmount);
            effectiveAmount = amount - feeAmount;
            _transfer(msg.sender, feeReceiver, feeAmount);
        }
        _transfer(msg.sender, to, effectiveAmount);
        return true;
    }

    function feeAvailable(address from, address to) internal view returns (bool) {
        // console.log("feeAvailable function");
        // console.log("from address");
        // console.log(from);
        // console.log("to address");
        // console.log(to);
        if(dex[from] == true || dex[to] == true) {
            // console.log("dex notification");
            if(whitelist[from] == true || whitelist[to] == true) {
                // console.log("whitelist");
                return false;
            }
            return true;
        }
        return false;
    }

    function calculateFeeAmount(uint256 amount, uint256 _feePercent) internal pure returns (uint256) {
        return (amount * _feePercent) / 1000;
    }
}
