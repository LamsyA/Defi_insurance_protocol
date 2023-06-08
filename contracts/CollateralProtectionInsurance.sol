// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollateralProtectionInsurance {
    address public owner;
    uint256 public collateralThreshold;

     struct loanPolicy{

        uint256 loanAmount;
        uint256 collateralThreshold;
        uint256 loanTime;
        uint256 loanToRepay;
        uint256 wallet;
        bool paid;
    }

    mapping(address => uint256) public loanCollateral;
    mapping(address => loanPolicy) public loan;
    
    event LoanCreated(address indexed borrower, uint256 loanAmount, uint256 collateralAmount);
    event CollateralReturned(address indexed borrower, uint256 collateralAmount);
    
    constructor(

        ) {
        owner = tx.origin;
    }
   
    uint256 private constant BASIC_LOAN = 0.5 ether;
    uint256 private constant PREMIUM_LOAN = 1 ether;
    uint256 private constant BASIC_LOAN_TIME = 30 days;
    uint256 private constant PREMIUM_LOAN_TIME = 60 days;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }
    
    function createLoan(uint256 loanAmount, uint256 collateralAmount) external onlyOwner{
        require(loanAmount > 0, "Loan amount must be greater than zero");
        require(collateralAmount > 0, "Collateral amount must be greater than zero");
        require(loan[msg.sender].loanAmount == 0, "loan already exist");

        if(loanAmount > BASIC_LOAN){
            // Premium loan 20% of loan interest;
            loan[owner] = loanPolicy(loanAmount, collateralAmount,block.timestamp + PREMIUM_LOAN_TIME,
            loanAmount + (loanAmount * 20)/ 100, 0, false);

        } else if (loanAmount <= BASIC_LOAN){
            // Premium loan 10% of loan interest;

            loan[owner] = loanPolicy(loanAmount, collateralAmount,block.timestamp + BASIC_LOAN_TIME, 
           loanAmount + (loanAmount * 10)/ 100, 0, false);
        }
        
        loanCollateral[msg.sender] = collateralAmount;
        emit LoanCreated(msg.sender, loanAmount, collateralAmount);
    }

    function collectLoan() external  payable  {
        require(loanCollateral[owner] != 0, "you do not have collateral");
        require(loan[owner].wallet == 0 , "wallet must be zero");

        require(loan[owner].collateralThreshold >= loan[owner].loanAmount, "Your collateral is too low");
        require(!loan[owner].paid, "loan not disbursed" );
        (bool sent,) = (owner).call{value: loan[owner].loanAmount}("");
        require(sent, "Failed to send Ether");

        loan[owner].wallet += loan[owner].loanAmount;

    }
    
      function payLoan() external payable  {
        require(loan[owner].loanToRepay > 0, "No loan available to pay");
        
        require(msg.value >= loan[owner].loanToRepay, "Insufficient  amount");
        

        require(!loan[owner].paid, "loan not disbursed" );
        payable (address(this)).transfer(msg.value);
        loan[owner].loanToRepay -= msg.value;

        // claim collateral
          loanCollateral[msg.sender] = 0;
        
        emit CollateralReturned(owner, msg.value);
    } 
    receive() payable external {}

   

}
