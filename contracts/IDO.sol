// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IDO is Ownable {

    using SafeERC20 for IERC20;

    using SafeMath for uint256;


    // Tokens for sale
    IERC20 public token;

    uint256 public tokenEthRate;

    // Max Allocation for one wallet
    uint256 public maxAllocation;

    // Min Allocation for one wallet
    uint256 public minAllocation;

    //token release time
    uint256 public releaseTime;

    // IDO end time
    uint256 public endTime;

    // Mapping which hold how much bought every wallet
    mapping(address => uint256) public allocations;

    //user buy event
    event PurchaseCompleted(address indexed buyer, uint256 amount);
    // token release event
    event TokensReleased(uint256 amount);

    event TokensClaimed(address indexed user, uint256 amount);

    // contructor
    constructor(address token_, uint256 tokenEthRate_, uint256 maxAllocation_, uint256 minAllocation_,uint256 releaseTime_,uint256 endTime_) {
        token = IERC20(token_);
        maxAllocation = maxAllocation_;
        minAllocation = minAllocation_;
        releaseTime = releaseTime_;
        endTime = endTime_;
        tokenEthRate = tokenEthRate_;
    }

    modifier onlyWhileOpen() {
        require(block.timestamp >= releaseTime && block.timestamp <= endTime, "IDO is not open");
        _;
    }

    modifier onlyWhileNotReleased() {
        require(block.timestamp < releaseTime, "Tokens have already been released");
        _;
    }


    //only admin set min allocation
    function setMinPurchaseAmount(uint256 _minAllocation) external onlyOwner {
        minAllocation = _minAllocation;
    }

    // only admin set max allocation
    function setMaxPurchaseAmount(uint256 _maxAllocation) external onlyOwner {
        maxAllocation = _maxAllocation;
    }

    // only admin set token eth rate
    function setTokenEthRate(uint256 _tokenEthRate) external onlyOwner {
        tokenEthRate = _tokenEthRate;
    }

    // only admin set release time
    function setReleaseTime(uint256 _releaseTime) external onlyOwner {
        releaseTime = _releaseTime;
    }

    // only admin set end time
    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    // only admin set token
    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    //user buy token
    function purchase() external payable onlyWhileOpen {
        require(msg.value >= minAllocation, "Below minimum purchase amount");
        require(msg.value <= maxAllocation, "Exceeds maximum purchase amount");
        address sender = msg.sender;
        uint256 tokenAmount = msg.value.mul(tokenEthRate);
        require(
            allocations[sender].add(tokenAmount) <= maxAllocation,
            "TokenSale: you try buy more than max allocation"
        );
        allocations[sender] = allocations[sender].add(msg.value);
        emit PurchaseCompleted(msg.sender, msg.value);
    }

    function claim() external payable onlyWhileNotReleased {
        uint256 claimAmount = allocations[msg.sender];
        require(claimAmount > 0,"You have no right to claim");
        require(token.balanceOf(address(this)) >= claimAmount, "Insufficient tokens in the contract");
        token.transfer(msg.sender, claimAmount);
        allocations[msg.sender] = 0;
        emit TokensClaimed(msg.sender,claimAmount);
    }

    function getUserAmount() public view returns (uint256) {
        return allocations[msg.sender];
    }

    function getTokensBalance() public view returns (uint256 balance) {
        balance = token.balanceOf(address(this));
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens() external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}
