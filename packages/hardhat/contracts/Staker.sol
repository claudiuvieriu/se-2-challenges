// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;

  event Stake(address staker, uint256 amount);

  // state machine - deadline in 4 days after contract deployment
  uint256 public deadline = block.timestamp + 94 hours;

  bool openForWithdraw = true;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier allowWithdraw() {
    require(openForWithdraw, "Can't withdraw");
    _;
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Canno't stake anymore!");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    require (msg.value > 0, "Staked amount must be grater than 0");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public allowWithdraw notCompleted {
    require (block.timestamp >= deadline, "Deadline not reached");
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      openForWithdraw = false;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() external allowWithdraw notCompleted {
    require (balances[msg.sender] > 0, "You don't have anything staked");

    //balance to withdraw
    uint256 withdrawAmount = balances[msg.sender];

    // Transfer the funds to the user
    (bool success, ) = msg.sender.call{value: withdrawAmount}("");
    require(success, "Withdrawal failed");

    balances[msg.sender] = 0;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
