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
}