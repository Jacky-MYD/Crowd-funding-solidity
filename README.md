本合约是一个比较完整的众筹合约，含：新建众筹项目，转账，打款，以及退款等功能！
编写合约时，可以直接在[线上](http://remix.ethereum.org)编写和测试部署

## 声明结构体和变量
   参与者只需记录参与者的地址和捐赠的金额
```
    struct funder {
        address funderAddress; // 捐赠者地址
        uint toMoney; // 捐赠money
    }
```
   发起者则需要较多的属性，如：受益地址，目标金额，是否募资完成等！！！
    另外，要通过funderMap(mapping)将捐赠者的id与捐赠者绑定在一起，从而得知是谁给受益人捐钱。
```
    struct needer {
        address payable neederAddress; // 受益人地址
        uint goal; // 众凑总数（目标）
        uint amount; // 当前募资金额
        uint isFinish; // 募资是否完成
        uint funderAccount; // 当前捐赠者人数
        mapping(uint => funder) funderMap; // 映射，将捐赠者的id与捐赠者绑定在一起，从而得知是谁给受益人捐钱
    }
```
   声明发起众凑的项目，并且通过neederMap(mapping)将受益人id与收益金额绑定在一起，从而可以更好的管理受益人
```
    address payable owner; // 合约发起者地址
    uint neederAmount; // 众筹项目id
    mapping (uint => needer) neederMap; // 通过mapping将受益人id与收益金额绑定在一起，从而可以更好的管理受益人
```
## 实例众凑项目
   create众凑项目的时候，直接给定一个自增的序号当作当前众凑项目的id。create项目时，要根据前面声明的needer结构体实例，参数要一一对应。
```
    /*
    * _neederAddress: 受益人地址（项目发起者）
    * _goal: 众筹目标
    */
    function NewNeeder(address payable _neederAddress, uint _goal) public {
        owner = msg.sender;
        neederAmount++;
        neederMap[neederAmount] = needer(address(_neederAddress), _goal, 0, 0, 0);
    }
```
## 捐赠者参与捐赠(转账)
   捐赠可以根据众凑项目id给该项目捐钱（转账），当合约的方法发生转账时必须用到**payable**关键字。另外，要先校验捐赠者钱包余额够不够本次捐赠的余额，还有校验该项目是否已终止，判断都有效的情况，此时会将本次捐赠的金额直接转账到当前合约中，同时记录捐赠人数和记录捐赠者。
```
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
```
## 项目结束，转账给受益人（也是属于转账）
   结束项目的原因有多种，但是这里只是用捐赠完成的原因作为例子。捐赠完成后，可以由合约发起者（本合约中也是受益者）发起将合约的钱转到自己的钱包地址中，这里同样发生了交易，所以也要用到关键字**payable**。然而，我们发现该方法中有一个**onlyOwner**修饰词，onlyOwner在下面会声明，表示只能是合约发起者才能调用该方法。
```
    // 捐赠是否完成，若完整，给受益人转账
    /*
    *_neederAmount: 众筹项目id
    */
    function Iscompelete(uint _neederAmount) public payable onlyOwner {
        needer storage _needer = neederMap[_neederAmount]; // 获取众筹项目
        require(_needer.amount >= _needer.goal);
        _needer.neederAddress.transfer(_needer.amount);
        _needer.isFinish = 1; // 若完成募资，则取消继续募资
    }
```
## 退钱（也是属于转账）
   当捐款的完成后，由于合约没有销毁，捐赠者还是可以继续捐赠的，因此会导致多出的钱仍在合约账户中，所以就有了该退款的方法。该方法是将合约上的钱根据捐赠者退回给捐赠者。
```
    //  募资完成时，退款给捐赠人
    function returnBack(uint _neederAmount) public payable {
        needer storage _needer = neederMap[_neederAmount]; // 获取众筹项目
        require(_needer.funderMap[_needer.funderAccount].funderAddress == msg.sender);
        uint returnMoney = _needer.funderMap[_needer.funderAccount].toMoney;
         
        uint balance = address(this).balance;
         
        balance -= returnMoney;
        msg.sender.transfer(returnMoney);
    }
```
## 查询已募资金额（合约的钱）
```
    // 查询合约余额
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
```
## 查询募资状态
```
   // 查看募资状态
    function showData(uint _neederAmount) public view returns(uint, uint, uint, uint) {
        return (neederMap[_neederAmount].goal, neederMap[_neederAmount].isFinish, neederMap[_neederAmount].amount,            neederMap[_neederAmount].funderAccount); 
    }
```
## 声明合约拥有者
```
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
```
## 合约销毁
```
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
```
