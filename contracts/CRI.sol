// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

contract Token{

    //owner of contract
    address owner;

    //mapping from user address to their corresponding balance
    mapping(address => uint256) balances;

    //mapping from user address to a mapping of other address that has permission to use a certain amount of money from the user
    mapping(address => mapping (address => uint256)) allowed;


    constructor() {
        owner = msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approve(address indexed _from, address indexed _to, uint _value);

    // minting new Token CRI
    function mint(uint _amount) public {
        require(msg.sender == owner);
        balances[msg.sender] += _amount;
    }

    // return the balance of the address passed in the argument
    function balanceOf(address _user) public view returns (uint) {
        return balances[_user];
    }

    // approve someone to spend a certain amount from the message sender's account
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    // return the alowed balance for the spender to deduct from the owner's account
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender]; 
    }


    function transfer(address _receiver, uint _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_receiver] = balances[_receiver] + _value;
        emit Transfer(msg.sender, _receiver, _value);
        return true;
    }

    // transfer money from sender to receiver
    function transferFrom(address _sender, address _receiver, uint _value) public {
        uint allowed_balance = allowed[_sender][msg.sender];
        require((balances[_sender] >= _value) && (allowed_balance >= _value)); // check if balance of sender is sufficient and the nnumber of allowance is bigger than the value
        balances[_receiver] += _value;
        balances[_sender] -= _value;
        allowed[_sender][msg.sender] -= _value;
        emit Transfer(_sender, _receiver, _value);
    }

}