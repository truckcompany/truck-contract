// SPDX-License-Identifier: Unlicensed
// Creator: Luiz Hemerly - @dreadnaugh

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {

    address taxRecipient;

    uint public antiSandwichSeconds = 12;
    uint public sellTaxValue = 1000*10**14; //@dev 2 digits after .
    uint public maxGas = 25 gwei;

    bool public antiSandwich = false;
    bool public sellTax = false;
    bool public antiFR = false;
    bool public notTax = true;

    mapping (address=>uint) public lastTrade;
    mapping (address=>bool) public whitelist;

    event setAntiSandwichStatus(bool status);
    event setAntiSandwichSeconds(uint _seconds);
    event setSellTaxStatus(bool status);
    event setSellTaxValue(uint _tax);
    event setMaxGasStatus(bool status);
    event setMaxGasSeconds(uint _maxGas);

    constructor() ERC20("Truck Company", "TRK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        antiSandwich = true;
        antiFR = true;
        sellTax = true;
        whitelist[msg.sender] = true;
        whitelist[address (this)] = true;
        taxRecipient = msg.sender;
    }

    function toogleAntiSandwich() external onlyOwner{
        antiSandwich = !antiSandwich;
        emit setAntiSandwichStatus(antiSandwich);
    }

    function setAntiSandwichSecs(uint seconds_) external onlyOwner{
        antiSandwichSeconds = seconds_;
        emit setAntiSandwichSeconds(antiSandwichSeconds);
    }

    function setWhitelist(address who) external onlyOwner{
        whitelist[who] = !whitelist[who];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (!whitelist[from] && notTax){
            if (antiSandwich){
                uint secondsPassed = block.timestamp - lastTrade[msg.sender];
                require(secondsPassed >= antiSandwichSeconds, "AntiBot: You cant trade yet.");
            }
            if (antiFR){
                require(tx.gasprice <= maxGas, "AntiBot: Cant pay that much gas price." );
            }
            if (sellTax){
                uint tax = amount*sellTaxValue/10**18;
                amount -= tax;
                notTax = false;
                _transfer(from, taxRecipient, tax);
                notTax = true;
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        lastTrade[msg.sender] = block.timestamp;
    }

}