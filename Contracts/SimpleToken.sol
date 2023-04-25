pragma solidity >=0.8.0 <0.9.0;

contract SimpleToken {
    mapping(address => uint) public balances;
    address public owner;
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
      name = name_;
      symbol = symbol_;
    }

    function getName() public view returns (string memory) {
      return name;
    }

    function getSymbol() public view returns (string memory) {
      return symbol;
    }

    function setOwner(address newOwner) public {
      if(owner != address(0)){
        assert(msg.sender == owner);
      } 
      owner = newOwner;
    }

    function get() public view returns (uint) {
      return balances[msg.sender];
    }

    function get(address addr) public view returns (uint) {
      return balances[addr];
    }

    function transfer(address destination, uint amount) public {
      require(balances[msg.sender] >= amount, "Invalid amount");
      require(msg.sender != destination, "Can't send to self");
      balances[destination] += amount;
      balances[msg.sender] -= amount;
    }

    function mint(uint amount) public {
      if(owner != address(0)){
        require(msg.sender == owner, "Only owner can mint");
      } 
      balances[msg.sender] += amount;
    }
}