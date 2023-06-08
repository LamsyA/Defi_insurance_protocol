// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoWalletInsurance {
    address public owner;
    bool public insured;
    uint256 public insuredAmount;
    uint256 public token;
    uint256 constant private BASIC_PREMIUM_INSURED_COVERAGE_TIME = 30 days;
    uint256 constant private STANDARD_PREMIUM_INSURED_COVERAGE_TIME = 60 days;

    uint256 public insuranceCoverageTime;

    mapping(address => uint256) public   walletBalance;
    mapping(address => uint256) public   walletTokenBalance;

    uint256 constant private BASIC_PREMIUM_POLICY = 1000000000;
    uint256 constant private STANDARD_PREMIUM_POLICY = 100000000;

    event InsurancePaymentReceived(address indexed payer, uint256 amount);
    event InsuranceClaimed(address indexed claimant, uint256 amount);

    constructor(uint256 _insuredAmount) {
        owner = tx.origin;
        insuredAmount = _insuredAmount;
    }

    function payInsurance() external payable {
        require(!insured, "User already insured");
        require(msg.value >= insuredAmount, "Invalid amount");
        require(block.timestamp > insuranceCoverageTime, "You cannot pay now");
        walletBalance[owner] += msg.value;

        if (msg.value < 1 ether) {
            insuranceCoverageTime = block.timestamp + BASIC_PREMIUM_INSURED_COVERAGE_TIME;
            token = (msg.value * 4 * insuranceCoverageTime) / BASIC_PREMIUM_POLICY;
        } else if (msg.value >= 1 ether) {
            insuranceCoverageTime = block.timestamp + STANDARD_PREMIUM_INSURED_COVERAGE_TIME;
            token = (msg.value * 9 * insuranceCoverageTime) / STANDARD_PREMIUM_POLICY;
        }

        insured = true;
        emit InsurancePaymentReceived(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    function claimInsurance() external payable onlyOwner() {
        require(insured, "You are not insured");
        require(block.timestamp > insuranceCoverageTime, "Your insurance has not expired yet");
        require(walletBalance[owner] != 0, "You have not paid for your insurance");

        insured = false;
        walletTokenBalance[owner] += token;
        (bool sent,) = (owner).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        emit InsuranceClaimed(msg.sender, address(this).balance);
    }

    function getwalletBalance() external  view returns(uint){
        return walletBalance[msg.sender];
    }
    function getwalletTokenBalance() external  view returns(uint){
        return walletTokenBalance[msg.sender];
    }

}
