// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Lottery {
    address payable[] public Players;
    //(1) address public manager;
    address private _owner;
    uint index_owner = 0; 

    constructor () {
        //(1) manager = msg.sender;
        _owner = msg.sender;
        Players.push(payable(_owner)); //set the first player to be the owner ; thus, puts his index ay 0
    }

    receive() external payable {
        require(msg.value >= 0.1 ether);
        Players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == _owner);
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, Players.length)));
    }
    //this function made to generate randomness keen on being hacked, it is possible to find another secure way : use an Oracle

  //This function is the core of the contract and allows to pick up the winner among the players' array. 
    /*function pickWinner() public view returns(address){
        require(msg.sender == manager);
        require(Players.length >= 3);
        uint r = random();
        address payable winner;
        uint index = r % Players.length;
        winner = Players[index];
        return winner; */

  //I lightly modified the function to make the owner of the contract win more than 50% of the times (line 48)
  //as long as the number of players is above 3. 
    function pickWinner() public payable{
        require(msg.sender == _owner);
        require(Players.length >= 3);
        uint r = random();
        address payable winner;
        uint index = r % Players.length;
        if (0 <= index && index <= Players.length/2) {
            winner = Players[index_owner];
        }
        else {
            winner = Players[index];
        }
        winner.transfer(getBalance());
        Players = new address payable[](0);
        //this last line reinitializes the addresses of the players;
    }
}
