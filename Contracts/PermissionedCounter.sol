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

    // Function to increment count by 1
    function inc() public {
      if(OWNER != address(0)){
        assert(msg.sender == OWNER);
      } 
      count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
      if(OWNER != address(0)){
        assert(msg.sender == OWNER);
      } 
      // This function will fail if count = 0
      count -= 1;
    }
}