// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;
import './interfaces/IERC20.sol';

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(address _acceptableToken, address _receiver, string memory _title, string memory _description, string memory _imageUrl, uint _amountTarget, uint _deadline) public {
        Campaign newCampaign = new Campaign(msg.sender, _acceptableToken, _receiver, _title, _description, _imageUrl, _amountTarget, _deadline);
        deployedCampaigns.push(address(newCampaign));
    }
}

contract Campaign {
    event ContributionEvent(
        address indexed contributor,
        uint256 amount,
        address token,
        uint256 timestamp
    );

    event WithdrawalEvent(
        address indexed receiver,
        uint256 amount,
        uint256 timestamp
    );

    event CampaignFinalizedEvent(
        address indexed owner,
        uint256 totalBalance,
        uint256 timestamp
    );

    struct Contribution {
        uint256 amount;
        uint256 sentAt;
    }

    struct ContributorInfo {
        uint256 totalContributions;
        Contribution[] contributions;
    }

    address public owner;
    address public acceptableToken;
    address public receiver;
    string public title;
    string public description;
    string public imageUrl;
    uint public amountTarget;
    mapping(address => ContributorInfo) public contributers;
    bool public isActive;
    uint public deadline;
    uint public createdAt;
    uint public endedAt;
    uint256 public achievedBalance;
    uint256 public currentBalance;

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, address _acceptableToken, address _receiver, string memory _title, string memory _description, string memory _imageUrl, uint _amountTarget, uint _deadline) {
        owner = _owner;
        acceptableToken = _acceptableToken;
        receiver = _receiver;
        title = _title;
        description = _description;
        imageUrl = _imageUrl;
        amountTarget = _amountTarget;
        deadline = _deadline;
        createdAt = block.timestamp;
        isActive = true;
    }

    function contribute(uint256 _amount) public{
        _isActive();
        IERC20 token = IERC20(acceptableToken);
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        
        token.transferFrom(msg.sender, address(this), _amount);
        achievedBalance += _amount;
        currentBalance += _amount;
        contributers[msg.sender].totalContributions += _amount;
        Contribution memory newContribution = Contribution({
            amount: _amount,
            sentAt: block.timestamp
        });
        contributers[msg.sender].contributions.push(newContribution);
        emit ContributionEvent(msg.sender, _amount, acceptableToken, block.timestamp);
    }

    function withdrawFunds(address _token, uint256 _amount) public restricted {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(_amount <= tokenBalance, "Insufficient token balance");

        if (_token == acceptableToken) {
            uint256 availableWithdraw = _availableWithdraw();
            require(_amount <= availableWithdraw, "Unavailable amount for withdraw");
        }

        token.transfer(receiver, _amount);
        if (_token == acceptableToken) {
            currentBalance -= _amount;
        }
        emit WithdrawalEvent(receiver, _amount, block.timestamp);
    }

    function finalizeAfterDeadline() public restricted {
        _isActive();
        require(block.timestamp > deadline, "The deadline has not been fulfilled yet");
        withdrawFunds(acceptableToken, currentBalance);
        isActive = false;
        endedAt = block.timestamp;
        emit CampaignFinalizedEvent(owner, achievedBalance, block.timestamp);
    }

    function _isActive() view private {
        require(isActive, "Campaign has ended");
    }

    function _availableWithdraw() private view returns (uint256) {
        // Calcula a porcentagem de tempo decorrido
        uint256 elapsedTime = block.timestamp - createdAt;
        uint256 totalDuration = deadline - createdAt;
        uint256 withdrawablePercentage = (elapsedTime * 100) / totalDuration;

        // Calcula o valor máximo que pode ser sacado proporcional ao tempo
        uint256 maxWithdrawable = (currentBalance * withdrawablePercentage) / 100;
        return maxWithdrawable;
    }
}