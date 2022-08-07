pragma solidity >=0.8.0 <0.9.0;

contract CounterWithLogs {
    uint public count;
    
    // Function to get the current count
    function get() public view returns (uint) {
      return count;
    }

    event CounterChange(address indexed sender, uint currentValue);

    // Function to increment count by 1
    function inc() public  {
      count += 1;
      emit CounterChange(msg.sender, count);
    }

    // Function to decrement count by 1
    function dec() public {
      // This function will fail if count = 0
      count -= 1;
      emit CounterChange(msg.sender, count);
    }
}