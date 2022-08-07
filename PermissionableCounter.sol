pragma solidity >=0.8.0 <0.9.0;

contract PermissionableCounter {
    uint public count;
    address public owner;

    function setOwner(address newOwner) public {
      if(owner != address(0)){
        assert(msg.sender == owner);
      } 
      owner = newOwner;
    }

    // Function to get the current count
    function get() public view returns (uint) {
      return count;
    }

    // Function to increment count by 1
    function inc() public {
      if(owner != address(0)){
        assert(msg.sender == owner);
      } 
      count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
      if(owner != address(0)){
        assert(msg.sender == owner);
      } 
      // This function will fail if count = 0
      count -= 1;
    }
}