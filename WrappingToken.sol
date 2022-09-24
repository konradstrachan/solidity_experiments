pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

contract WrappingToken is IERC20 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;
    uint supply;

    address public operator;
    string public name;
    string public symbol;

    event BurnedToken(address indexed sender, uint amount);

    constructor(string memory name_, string memory symbol_, address operator_) {
      operator = operator_;
      name = name_;
      symbol = symbol_;
      supply = 0;
    }

    function getName() public view returns (string memory) {
      return name;
    }

    function getSymbol() public view returns (string memory) {
      return symbol;
    }

    function setOperator(address newOwner) public {
      require(msg.sender == operator, "Originator not operator");
      operator = newOwner;
    }

    //
    // interface IERC20
    //

    function balanceOf(address account) external view override returns (uint) {
      return balances[account];
    }

    function totalSupply() external view override returns (uint) {
        return supply;
    }

    function allowance(address owner, address spender) external view override returns (uint) {
        // Get for an owning address the allowance for a spender
        return allowances[owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        // Allow for this address (msg.sender) a certain spender (supplied) for set amount
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        require(balances[msg.sender] >= amount, "Invalid amount");
        require(msg.sender != recipient, "Can't send to self");
        
        if(recipient == address(this)){
            _burn(amount, msg.sender);
        }
        else {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool)
    {
        // Check the address who will have funds spend has allowed the spender (the sender) to spend this amount
        require(allowances[sender][msg.sender] <= amount, "Spending this amount is not allowed");
        require(balances[sender] >= amount, "Invalid amount");
        require(sender != recipient, "Can't send to self");

        allowances[msg.sender][sender] -= amount;

        if(recipient == address(this)){
            _burn(amount, sender);
        }
        else {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        }

        return true;
    }

    //
    //  Wrapping functions
    //

    function mint(uint amount, address recipient) public {
        require(msg.sender == operator, "Only operator can mint");
        balances[recipient] += amount;
        supply += amount;
    }

    function _burn(uint amount, address owner) private {
        require(amount <= balances[owner], "Can't burn more than owned");
        balances[owner] -= amount;
        supply -= amount;
        emit BurnedToken(msg.sender, amount);
    }
}