pragma solidity >=0.8.0 <0.9.0;

contract PermissionedCounter {
    uint public count;
    address public immutable OWNER;

    constructor(){
      OWNER = msg.sender;
    }
    
    // Function to get the current count
    function get() public view returns (uint) {
      return count;
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == OWNER, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Function to increment count by 1
    function inc() public onlyOwner {
      count += 1;
    }

    // Function to decrement count by 1
    function dec() public onlyOwner {
      // This function will fail if count = 0
      count -= 1;
    }
}