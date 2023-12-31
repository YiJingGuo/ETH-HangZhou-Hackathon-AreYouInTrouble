## ETH Hangzhou Hackathon Project

## AreYouInTrouble 应对突发事件的遗产继承合约

本项目合约主要分为工厂合约和主逻辑合约。

### Factory工厂合约

本合约的主要功能是：
1. 创建每个用户所对应的“继承合约”。
2. 根据创建合约所需要的salt值预测出部署的合约地址。
3. 为了方便前端读数据，并避免增加后端，所以增加了记录继承人所继承的合约地址，维持人所维持的合约地址数据接口。

### AreYouInTrouble主逻辑合约

该合约先部署为逻辑合约，然后工厂合约创建“继承合约”。

该合约的功能有：
1. 心跳功能：指定维持心跳者，移除维持者，更新最新心跳时间，设置心跳时间间隔。
2. 继承人相关：指定继承人、继承金额、记录继承的代币类型、代币地址、继承人claim代币。
3. 维持者相关：指定维持者、移除维持者、维持心跳方法。
4. 代币相关：对于原生代币，可以选择质押的方式，或者进行包装，对于ERC20代币，则用户把需要继承的总额度授权给所对应的“继承合约”，对于ERC721代币，同样使用授权的方式。