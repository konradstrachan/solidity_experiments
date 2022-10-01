pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EscrowERC20
{
    uint private amountTarget;
    IERC20 token;

    uint private deadline;
    address private beneficiary;

    mapping (address => uint) contributors;

    constructor(IERC20 token_, uint deadline_, uint amountTarget_, address beneficiary_) {
        token = token_;
        deadline = deadline_;
        amountTarget = amountTarget_;
        beneficiary = beneficiary_;
    }

    function hasExpired() public view returns (bool)
    {
        return block.timestamp >= deadline;
    }

    function hasEnoughFunds() public view returns (bool)
    {
        return token.balanceOf(address(this)) >= amountTarget;
    }

    function stake(uint amount) public
    {
        // tx for sending more funds to the pot if deadline hasn't been met yet
        require(!hasExpired(), "Too late to deposit");
        require(token.allowance(msg.sender, address(this)) > amount, "Allowance insufficient");
        
        // transfer from address to this contract address
        bool result = token.transferFrom(msg.sender, address(this), amount);
        require(result == true, "Staking failed");
        
        contributors[msg.sender] = contributors[msg.sender] + amount;
    }

    function complete() public
    {
        // tx for sending funds to destination if time elapsed and amount raised greater than threshold
        require (hasExpired(), "Too early to complete");
        require (hasEnoughFunds(), "Unable sweep funds to beneficiary if target not met");

        // send all funds to beneficiary
        bool result = token.transfer(beneficiary, token.balanceOf(address(this)));
        require(result == true, "Complete sweeping failed");
    }

    function withdraw() public
    {
        // tx for reclaiming funds if time eslapese and amount raised less than threshold
        // msg.sender needs to be the original depositor
        require (hasExpired(), "Too early to claim back funds");
        require (!hasEnoughFunds(), "Unable to claim funds if successfully funded");
        require (contributors[msg.sender] >= 0, "No funds for user to request returned");

        // send back funds contributed by this caller
        uint amountToSend = contributors[msg.sender];
        contributors[msg.sender] = 0;

        bool result = token.transfer(msg.sender, amountToSend);
        require(result == true, "Withdraw failed");
    }
}