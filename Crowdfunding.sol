//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract Crowdfunding {

    //persons involved
    address public admin;
    mapping (address => uint) public contributors;
    uint public numContributors;
    uint public minContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;

    struct Request{ 
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    constructor (uint _goal, uint _deadline) { //deadline in seconds
        goal = _goal;
        deadline = block.timestamp + _deadline;
        //the front-end translates the timestamp (seconds) into human redeable date
        minContribution = 100 wei;
        admin = msg.sender;   
    }
    
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minContribution, "Minimum contribution not met, please add some more");

        if(contributors[msg.sender] == 0) {
            numContributors++;
        } //doesn't count the same contributor twice
    
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }    
        
    receive() payable external{
        contribute();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRefund() public{
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);

        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "The only caller of the function can be the admin");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    //requests are created ; now how to vote for each one of them ?
    function voteRequest(uint _requestIndex) public {
        require(contributors[msg.sender] > 0, "Error : We haven't identified you as a contributor");
        Request storage thisRequest = requests[_requestIndex]; // we take the index of the request
        require(thisRequest.voters[msg.sender] == false, "You can not vote twice");
        thisRequest.voters[msg.sender] == true;
        thisRequest.numVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin {
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "the request has not been completed");
        require(thisRequest.numVoters > numContributors/2); 
        //50% voted for this request
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }

}
