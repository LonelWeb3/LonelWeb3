//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

interface ERC20Interface {
    ///Only these 3 functions are mandatory
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
// if we don't implement all the functions in the interface, 
//we have to mask them to not get an error
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, int tokens);

}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;
    // balances[0x111...] = 100;

    mapping(address => mapping(address => uint)) allowed;
    //allowed[0x111...][Ox2434] = 100;
    //double mapping for allowance
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply; 
        // the founder gets all the tokens
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns(bool success) {
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
        //if true, the transfer has been successful
        // if failure, the function execution is revert

        //a fully compliant ERC-20 standard token implements all the functions in the interface
    }

    function allowance(address tokenOwner, address spender) view public override returns(uint){
        //mapping(address => mapping(address => uint)) allowed;
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens; 
        return true;
    }
}

contract ICO is Cryptos {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether;
    //1ETH = 1000 CRPT, 1 CRPT = 0.001ETH
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    //The ICO starts after the contract is deployed
    //for additional time, add the number of seconds 
    uint public saleEnd = saleStart + 604800;
    //ICO ends in one week
    uint public tokenTradeStart = saleEnd + 604800;
    //tokens are transferrable only one week after the ICO ends
    uint public maxInvest = 5 ether;
    uint public minInvest = 0.01 ether;

    enum State {beforeStart, Running, afterEnd, halted}

    State public ICOState;

    constructor(address payable _deposit) {
        _deposit = deposit;
        admin = msg.sender;
        ICOState = State.beforeStart;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin {
        ICOState = State.halted;
    }

    function resume() public onlyAdmin{
        ICOState = State.Running;
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State){
        if(ICOState == State.halted) {
            return State.halted;
        }
        else if(block.timestamp < saleStart){
            return State.beforeStart;
        }

        else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.Running;
        }

        else {
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    //invest : you send ETH to receive CRPT
    function invest() payable public returns(bool){
        ICOState = getCurrentState();
        require(ICOState == State.Running);
        require(msg.value >= minInvest && msg.value <= maxInvest);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        //The number of the tokens received when sent ETH
        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens;   

        //transfer the amount of tokens sent to the contract to the deposit address
        deposit.transfer(msg.value);

        //trigger the event
        emit Invest(msg.sender, msg.value, tokens);

        return true;
        //the investor is now on the ICO

    }

    receive() external payable {
        invest();
    }

    //Lock up the tokens after the ICO ends to avoid sells and prevent the token value to collapse
    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transfer(to, tokens); // or super.transfer(to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transferFrom(from, to, tokens);
        return true;
    }    

    //Another practice : burn the tokens that have not been sold during the ICO
    //at the saleEnd, it is possible that the ICO received less than the target
    //the rest is in possession of the owner
    //either the owner keeps them, or burns them, which generally leads to increase the price of the token
    function burn() public returns(bool){
        ICOState = getCurrentState();
        require(ICOState == State.afterEnd);
        //the balance of the owner of the supply is reduced with the number of the tokens that are left
        balances[founder] = 0; 
        // the tokens have vanished
        return true;
    }

}
