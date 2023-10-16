// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interface/IAreYouInTrouble.sol";
import "./interface/IFactory.sol";

contract AreYouInTrouble is IAreYouInTrouble, Initializable{
    address public factoryAddress;

    address public owner;
    uint256 public stakedEtherBalances;
    uint256 public lastHeartBeat;
    uint256 public maintainInterval;
    address[] public inheritorList;
    address[] public maintainerList;
    
    mapping(address => bool) public maintainer;
    mapping(address => uint256) public inheritanceEther;
    // inheritor => ERC20Addr => amount
    mapping(address => mapping(address => uint256)) public inheritanceERC20;
    // inheritor => ERC721Addr => ID[]
    mapping(address => mapping(address => uint256[])) public inheritanceERC721;

    // inheritor => ERC20List
    mapping(address => address[]) public inheritanceERC20List;
    mapping(address => address[]) public inheritanceERC721List;

    // Since there is no need to transfer the Owner function
    modifier onlyOwner() {
        if(msg.sender != owner){
            revert NotOwnerAccount(msg.sender);
        }
        _;
    }

    modifier onlyMaintainer() {
        if(maintainer[msg.sender] == false){
            revert NotMaintainerAccount(msg.sender);
        }
        _;
    }

    function initialize(address _owner, address _factoryAddress) external initializer {
        owner = _owner;
        factoryAddress = _factoryAddress;
        lastHeartBeat = block.timestamp;
        maintainer[_owner] = true;
    }

    /**
     * @notice 一次性设置继承人、继承金额、维持者等等。
     * @param _tokenAddress 需要给继承人的ERC20代币地址，如果是主网币，则输入0地址
     * @param _inheritor 继承人地址
     * @param _inheritanceAmount 继承的金额
     * @param _maintainInterval 维持心跳时间间隔
     * @param _maintainer 维持者
     */
    function set(address _tokenAddress, address _inheritor, uint256 _inheritanceAmount, uint256 _maintainInterval, address _maintainer) external onlyOwner{
        lastHeartBeat = block.timestamp;
        if(_tokenAddress == address(0)) {
            setInheritanceEther(_inheritor, _inheritanceAmount);
        } else {
            setInheritanceERC20(_inheritor, _tokenAddress, _inheritanceAmount);
        }
        IFactory factory = IFactory(factoryAddress);
        factory.addFatherList(_inheritor, address(this));
        addMaintainer(_maintainer);
        maintainInterval = _maintainInterval;
    }
    
    /**
     * @notice 仅仅维持者来调用，维持心跳。
     */
    function maintainHeartBeat() external onlyMaintainer {
        lastHeartBeat = block.timestamp;
    }

    /**
     * @notice 修改维持心跳时间间隔
     * @param _maintainInterval 修改维持的时间间隔
     */
    function setMaintainInterval(uint256 _maintainInterval) onlyOwner {
        maintainInterval = _maintainInterval;
    }

    /**
     * @notice 仅管理员调用，添加维持者。
     * @param addr 新增的维持者地址
     */
    function addMaintainer(address addr) public onlyOwner {
        maintainer[addr] = true;
        IFactory factory = IFactory(factoryAddress);
        factory.addMaintainAddr(addr, address(this));
        _addMaintainerList(addr);
        emit AddMaintainer(addr, address(this));
    }

    /**
     * @notice 仅管理员调用，移除维持者。
     * @param addr 移除维持者地址
     */
    function removeMaintainer(address addr) external onlyOwner {
        maintainer[addr] = false;
        IFactory factory = IFactory(factoryAddress);
        factory.removeMaintainAddr(addr, address(this));
        _removeMaintainList(addr);
        emit RemoveMaintainer(addr, address(this));
    }

    /**
     * @notice 质押主网币到本合约，让未来继承人从合约中取出主网币，调用的时候更新心跳。
     */
    function stakeEther() public payable onlyOwner {
        if (msg.value == 0) {
            revert StakeAmount(address(0), msg.value);
        }
        stakedEtherBalances += msg.value;
        _maintainHeartBeat();
        emit StakedEther(msg.value);
    }

    /**
     * @notice 设置主网币继承人与金额
     * @dev 无需检查金额，即使金额为0，也只是继承人未来claim不了。
     * @param _inheritor 继承人
     * @param _inheritanceAmount 继承金额
     */
    function setInheritanceEther(address _inheritor, uint256 _inheritanceAmount) public onlyOwner {
        if(_inheritor == address(0)){
            revert InheritorAddressIsZero();
        }
        inheritanceEther[_inheritor] = _inheritanceAmount;
        _addInheritorList(_inheritor);
        IFactory factory = IFactory(factoryAddress);
        factory.addFatherList(_inheritor, address(this));
        emit SetInheritanceEther(_inheritor, _inheritanceAmount, address(this), owner);
    }

    /**
     * @notice 设置ERC20代币继承人与金额
     * @param _inheritor 继承人
     * @param _ERC20Addr ERC20代币地址
     * @param _inheritanceAmount 继承金额
     */
    function setInheritanceERC20(address _inheritor, address _ERC20Addr, uint256 _inheritanceAmount) public onlyOwner {
        if(_inheritor == address(0)){
            revert InheritorAddressIsZero();
        }
        if(_ERC20Addr == address(0)){
            revert ERC20AddressIsZero();
        }
        inheritanceERC20[_inheritor][_ERC20Addr] = _inheritanceAmount;
        _addInheritorList(_inheritor);
        _addInheritanceERC20List(_inheritor, _ERC20Addr);
        IFactory factory = IFactory(factoryAddress);
        factory.addFatherList(_inheritor, address(this));
        emit SetInheritanceERC20(_inheritor, _ERC20Addr, _inheritanceAmount, address(this), owner);
    }

    /**
     * @notice 设置ERC721继承人和继承的NFT ID
     * @param _inheritor 继承人
     * @param _ERC721Addr ERC721地址
     * @param _inheritanceERC721ID NFT ID列表
     */
    function setInheritanceERC721(address _inheritor, address _ERC721Addr, uint256[] calldata _inheritanceERC721ID) external onlyOwner {
        if(_inheritor == address(0)){
            revert InheritorAddressIsZero();
        }
        if(_ERC721Addr == address(0)){
            revert ERC721AddressIsZero();
        }
        inheritanceERC721[_inheritor][_ERC721Addr] = _inheritanceERC721ID;
        _addInheritorList(_inheritor);
        _addInheritanceERC20List(_inheritor, _ERC721Addr);
        IFactory factory = IFactory(factoryAddress);
        factory.addFatherList(_inheritor, address(this));
        emit SetInheritanceERC721(_inheritor, _ERC721Addr, _inheritanceERC721ID, address(this), owner);
    }

    /**
     * @notice 继承人claim质押在本合约中的主网币，将检查是否超过了心跳时间间隔，当前继承人的继承余额。
     * @dev 无需维护一个继承人列表，因为通过地址映射的余额可以判断出是否是继承人。
     * @param _amount claim的金额，如果金额小于可继承的余额，但大于合约中的余额，则claim合约中的所有余额。
     */
    function claimStakedEther(uint256 _amount) external {
        if(block.timestamp - lastHeartBeat < maintainInterval){
            revert timeInterval(lastHeartBeat, maintainInterval, block.timestamp);
        }
        if(inheritanceEther[msg.sender]  < _amount){
             revert InheritedBalanceLack(msg.sender);
        }

        inheritanceEther[msg.sender] -= _amount;
        uint256 balances = address(this).balance;

        if(balances >= _amount){
            (bool success,) = payable(msg.sender).call{value: _amount}("");
            require(success, "transfer failed");
        } else {
            (bool success,) = payable(msg.sender).call{value: balances}("");
            require(success, "transfer failed");
        }
    }
    /**
     * @notice 继承人claim管理员钱包中的代币。
     * @dev 若钱包余额不足，在safeTransferFrom函数中报错。
     * @param _ERC20Addr ERC20代币地址。
     * @param _amount claim的代币数量。
     */
    function claimApprovedERC20(address _ERC20Addr, uint256 _amount) external {
        if(block.timestamp - lastHeartBeat < maintainInterval){
            revert timeInterval(lastHeartBeat, maintainInterval, block.timestamp);
        }
        if(inheritanceERC20[msg.sender][_ERC20Addr]  < _amount){
             revert InheritedBalanceLack(msg.sender);
        }

        IERC20 token = IERC20(_ERC20Addr);
        inheritanceERC20[msg.sender][_ERC20Addr] -= _amount;

        token.transferFrom(owner, msg.sender, _amount);
    }

    /**
     * @notice 继承人claim授权给本合约的NFT。
     * @dev 只需检查mapping对应的ID数组是否为空，来判断是否是继承人。
     * @param _ERC721Addr ERC721地址
     * @param tokenID token ID
     */
    function claimApprovedERC721(address _ERC721Addr, uint256 tokenID) external {
        if(block.timestamp - lastHeartBeat < maintainInterval){
            revert timeInterval(lastHeartBeat, maintainInterval, block.timestamp);
        }
        IERC721 token = IERC721(_ERC721Addr);

        uint256[] memory inheritanceERC721ID = inheritanceERC721[msg.sender][_ERC721Addr];
        if (inheritanceERC721ID.length == 0){
            revert inheritanceERC721IDIsNULL(msg.sender, _ERC721Addr);
        }

        for(uint256 i = 0; i < inheritanceERC721ID.length; ++i){
            if(inheritanceERC721ID[i] == tokenID){
                token.safeTransferFrom(address(this), msg.sender, tokenID);
                break;
            }
        }
    }

    /**
     * @notice 把质押在本合约中的主网币提取出来。
     * @param amount 取回金额
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    /**
     * @notice 获取当前维持者列表
     */
    function getMaintainerList() public view returns (address[] memory) {
        return maintainerList;
    }
    
    /**
     * @notice 获取当前继承人列表
     */
    function getInheritorList() public view returns (address[] memory) {
        return inheritorList;
    }

    /**
     * @notice 获取指定继承人所继承的ERC20代币地址列表
     * @param _addr 继承人地址
     */
    function getInheritanceERC20List(address _addr) public view returns (address[] memory) {
        return inheritanceERC20List[_addr];
    }

    /**
     * @notice 获取指定继承人所继承的ERC721地址列表
     * @param _addr 继承人地址
     */
    function getInheritanceERC721List(address _addr) public view returns (address[] memory) {
        return inheritanceERC721List[_addr];
    }

    function _maintainHeartBeat() private {
        lastHeartBeat = block.timestamp;
    }

    function _addInheritorList(address _addr) private {
        bool exists = false;
        for(uint256 i = 0; i < inheritorList.length; ++i){
            if(inheritorList[i] == _addr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            inheritorList.push(_addr);
        }
    }

    function _addMaintainerList(address _addr) private {
        bool exists = false;
        for(uint256 i = 0; i < maintainerList.length; ++i){
            if(maintainerList[i] == _addr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            maintainerList.push(_addr);
        }
    }

    function _removeMaintainList(address _addr) private {
        for (uint256 i = 0; i < maintainerList.length; ++i) {
            if (maintainerList[i] == _addr) {
                address last = maintainerList[maintainerList.length - 1];
                maintainerList[i] = last;
                maintainerList.pop();
            }
        }
    }

    function _addInheritanceERC20List(address _addr, address _ERC20Addr) private {
        bool exists = false;
        for(uint256 i = 0; i < inheritanceERC20List[_addr].length; ++i){
            if(inheritanceERC20List[_addr][i] == _ERC20Addr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            inheritanceERC20List[_addr].push(_ERC20Addr);
        }
    }

    function _addInheritanceERC721List(address _addr, address _ERC721Addr) private {
        bool exists = false;
        for(uint256 i = 0; i < inheritanceERC721List[_addr].length; ++i){
            if(inheritanceERC721List[_addr][i] == _ERC721Addr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            inheritanceERC721List[_addr].push(_ERC721Addr);
        }
    }


}