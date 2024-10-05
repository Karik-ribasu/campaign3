// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;
import './interfaces/IERC20.sol';

contract Campaign {
    event Contribution(
        address indexed contributor,
        uint256 amount,
        address token,
        uint256 timestamp
    );

    string public title;
    string public description;
    string public imageUrl;
    uint public amountTarget;
    mapping(address => bool) public allowedApprovers;
    mapping(address => mapping(address => uint256)) public contributers;
    uint256 public minimumContribution;
    bool public isActive;
    uint public deadline;
    uint public createdAt;
    mapping(address => uint256) public tokenBalance;

    constructor(string memory titleParam, string memory descriptionParam, string memory imageUrlParam, uint amountTargetParam, uint256 minimumContributionParam, uint deadlineParam) {
        title = titleParam;
        description = descriptionParam;
        imageUrl = imageUrlParam;
        amountTarget = amountTargetParam;
        minimumContribution = minimumContributionParam;
        deadline = deadlineParam;
        createdAt = block.timestamp;
        isActive = true;
    }

        function contribute(uint256 amount, address token) public payable{
        require(isActive, "Campaign is not active");
        require(block.timestamp < deadline, "Campaign has ended");
        require((amount > 0 && token != address(0) && msg.value == 0) || (msg.value > 0 && token == address(0)), "Is not allowed to send native currency and erc20 tokens at once");

        if (token != address(0) || msg.value == 0) {
            IERC20 ierc20Token = IERC20(token);
            require(ierc20Token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
            ierc20Token.transferFrom(msg.sender, address(this), amount);
            tokenBalance[token] += amount;
            allowedApprovers[msg.sender] = true;
            contributers[msg.sender][token] += amount;
            emit Contribution(msg.sender, amount, token, block.timestamp);
        } else {
            require(msg.value >= minimumContribution, "Contribution must meet the minimum requirement");
            tokenBalance[address(0)] += msg.value; // increase native token balance
            allowedApprovers[msg.sender] = true;
            contributers[msg.sender][address(0)] += msg.value;
            emit Contribution(msg.sender, msg.value, token, block.timestamp);
        }
    }
}