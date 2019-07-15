pragma solidity ^0.5.8;

contract zhongcouTest {
    
    // 捐赠者
    struct funder {
        address funderAddress; // 捐赠者地址
        uint toMoney; // 捐赠money
    }
    // 受益人对象
    struct needer {
        address payable neederAddress; // 受益人地址
        uint goal; // 众凑总数（目标）
        uint amount; // 当前募资金额
        uint isFinish; // 募资是否完成
        uint funderAccount; // 当前捐赠者人数
        mapping(uint => funder) funderMap; // 映射，将捐赠者的id与捐赠者绑定在一起，从而得知是谁给受益人捐钱
    }
    
    uint neederAmount; // 众筹项目id
    mapping (uint => needer) neederMap; // 通过mapping将受益人id与收益金额绑定在一起，从而可以更好的管理受益人
    
    // 新建众筹项目
    /*
    * _neederAddress: 受益人地址（项目发起者）
    * _goal: 众筹目标
    */
    function NewNeeder(address payable _neederAddress, uint _goal) public {
        neederAmount++;
        neederMap[neederAmount] = needer(address(_neederAddress), _goal, 0, 0, 0);
    }
    
    // 捐赠者给指定众筹id打钱
    /*
    *_neederAmount: 众筹项目id
    *_address: 捐赠者地址
    */
    function contribue(address _address, uint _neederAmount) public payable {
        require(msg.value > 0);
        needer storage _needer = neederMap[_neederAmount]; // 获取众筹项目
        require(_needer.isFinish == 0); // 募资是否完成， 若完成则取消当前捐款
        _needer.amount += msg.value; // 捐赠金额
        
        _needer.funderAccount++; // 捐赠者个数
        _needer.funderMap[_needer.funderAccount] = funder(_address, msg.value); // 标记捐赠者及捐赠金额
    }
    
    // 捐赠是否完成，若完整，给受益人转账
     /*
    *_neederAmount: 众筹项目id
    */
    function Iscompelete(uint _neederAmount) public payable{
        needer storage _needer = neederMap[_neederAmount]; // 获取众筹项目
        require(_needer.amount >= _needer.goal);
        _needer.neederAddress.transfer(_needer.amount);
        _needer.isFinish = 1; // 若完成募资，则取消继续募资
    }
    
    //  募资完成时，退款给捐赠人
    function returnBack(uint _neederAmount) public payable {
        needer storage _needer = neederMap[_neederAmount]; // 获取众筹项目
        require(_needer.funderMap[_needer.funderAccount].funderAddress == msg.sender);
        uint returnMoney = _needer.funderMap[_needer.funderAccount].toMoney;
         
        uint balance = address(this).balance;
         
        balance -= returnMoney;
        msg.sender.transfer(returnMoney);
    }
    
    // 查询合约余额
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // 查看募资状态
    function showData(uint _neederAmount) public view returns(uint, uint, uint, uint) {
        return (neederMap[_neederAmount].goal, neederMap[_neederAmount].isFinish, neederMap[_neederAmount].amount, neederMap[_neederAmount].funderAccount); 
    }
}