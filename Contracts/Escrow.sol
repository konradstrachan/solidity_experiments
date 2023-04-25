pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract YourContract is
    Ownable
{
    uint private amountTarget;
    uint private deadline;
    address payable private beneficiary;

    mapping (address => uint) contributors;

    constructor(uint deadline_, uint amountTarget_, address payable beneficiary_) {
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
        return address(this).balance >= amountTarget;
    }

    function stake() public payable
    {
        // tx for sending more funds to the pot if deadline hasn't been met yet
        require (!hasExpired(), "Too late to deposit");
        contributors[msg.sender] = contributors[msg.sender] + msg.value;
    }

    function complete() public
    {
        // tx for sending funds to destination if time elapsed and amount raised greater than threshold
        require (hasExpired(), "Too early to complete");
        require (hasEnoughFunds(), "Unable sweep funds to beneficiary if target not met");

        // send all funds to beneficiary
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
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

        (bool success, ) = address(msg.sender).call{value: amountToSend}("");
        require(success, "Failed to send Ether");
    }
}