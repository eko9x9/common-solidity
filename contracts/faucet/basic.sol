// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Faucet {

    struct NextReward {
        uint timestamp;
    }
    uint public cooldownFundTimeStamp = 86400; 
    uint public amountFaucet;
    address owner;
    mapping (address => NextReward) public userNextReward;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner!");
        _;
    }

    constructor (uint _amountFaucet) {
        amountFaucet = _amountFaucet;
        owner = msg.sender;
    }

    event Received(address, uint);

    function fundUser(address _user) public onlyOwner {
        if(userNextReward[_user].timestamp == 0){
            (bool sent, ) = payable(_user).call{value: amountFaucet}("");
            require(sent, "Failed to send Ether");
            userNextReward[_user].timestamp = block.timestamp + cooldownFundTimeStamp;
        }else{
            require(block.timestamp > userNextReward[_user].timestamp, "User on cooldown!");
            (bool sent, ) = payable(_user).call{value: amountFaucet}("");
            require(sent, "Failed to send Ether");
            userNextReward[_user].timestamp = block.timestamp + cooldownFundTimeStamp;
        }
    }

    function setCooldownFund(uint _interval) public onlyOwner {
        cooldownFundTimeStamp = _interval;
    }

    function setAmountFaucet(uint _amunt) public onlyOwner {
        amountFaucet = _amunt;
    }

    function getTimeStamp() public view returns(uint){
        return block.timestamp;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}