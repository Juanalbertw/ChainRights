// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

contract Token{

    //owner of contract
    address owner;
    uint currentSupply;
    uint totalSupply;

    //mapping from user address to their corresponding balance
    mapping(address => uint256) balances;

    //mapping from user address to a mapping of other address that has permission to use a certain amount of money from the user
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) private isMinter;


    constructor() {
        totalSupply = 1000000000;
        currentSupply = 0;
        owner = msg.sender;
        isMinter[owner] = true; // Owner is a minter by default
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approve(address indexed _from, address indexed _to, uint _value);
    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // minting new Token CRI
    function mint(uint _amount) public {
        require(isMinter[msg.sender], "Caller is not a minter");
        balances[msg.sender] += _amount;
        currentSupply += _amount;
    }

    // return the balance of the address passed in the argument
    function balanceOf(address _user) public view returns (uint) {
        return balances[_user];
    }

     // Owner can add new minters
    function addMinter(address _minter) public onlyOwner {
        isMinter[_minter] = true;
        emit MinterAdded(_minter);
    }

    // Owner can remove minters
    function removeMinter(address _minter) public onlyOwner {
        isMinter[_minter] = false;
        emit MinterRemoved(_minter);
    }

    function mintTo(address _to, uint _amount) public {
        require(isMinter[msg.sender], "Caller is not authorized to mint");
        balances[_to] += _amount;
        currentSupply += _amount;
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

    // Function to get the total supply of tokens
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    // Function to get the current supply of tokens
    function getCurrentSupply() public view returns (uint256) {
        return currentSupply;
    }
}