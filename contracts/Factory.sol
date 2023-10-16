// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/IAreYouInTrouble.sol";

contract Factory {

    event InstanceCreation(address indexed instance, address implemention);

    using Clones for address;

    mapping(address => bool) public createInstance;

    // 维持心跳者地址 => “继承合约”列表
    mapping(address => address[]) public maintainerList;

    // 继承人 => “继承合约”列表
    mapping(address => address[]) public fatherList;

    modifier onlyInstance {
        require(createInstance[msg.sender] == true, "Not created instance");
        _;
    }

    function predictAddress(address _implemention, bytes32 salt) public view returns (address) {
        return _implemention.predictDeterministicAddress(salt);
    }

    function create(
        address _implemention,
        bytes32 salt,
        address _owner
    ) public returns (address instance) {
        instance = _implemention.cloneDeterministic(salt);
        IAreYouInTrouble(instance).initialize(_owner, address(this));
        createInstance[instance] = true;
        emit InstanceCreation(instance, _implemention);
    }

    /**
     * @notice 返回继承人所继承的合约列表
     * @param _addr 继承人地址
     */
    function getFatherList(address _addr) public view returns (address[] memory) {
        return fatherList[_addr];
    }

    /**
     * @notice 返回该维持者所维持的“继承合约”列表
     * @param _addr 维持心跳者地址
     */
    function getMaintainerList(address _addr) public view returns (address[] memory) {
        return maintainerList[_addr];
    }

    /**
     * @notice 记录继承人所继承的合约地址
     * @param inheritor 继承人地址
     * @param contractAddr 所继承的合约地址
     */
    function addFatherList(address inheritor, address contractAddr) external onlyInstance{
        require(inheritor != address(0), "maintainer addr is 0");
        require(contractAddr != address(0), "contractAddr addr is 0");

        bool exists = false;
        for(uint256 i = 0; i < fatherList[inheritor].length; ++i){
            if(fatherList[inheritor][i] == contractAddr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            fatherList[inheritor].push(contractAddr);
        }
    }

    /**
     * @notice 记录该维持者维持的合约地址
     * @param maintainer 维持者地址
     * @param contractAddr 所维持心跳的合约地址
     */
    function addMaintainAddr(address maintainer, address contractAddr) external onlyInstance{
        require(maintainer != address(0), "maintainer addr is 0");
        require(contractAddr != address(0), "contractAddr addr is 0");

        bool exists = false;
        for(uint256 i = 0; i < maintainerList[maintainer].length; ++i){
            if(maintainerList[maintainer][i] == contractAddr){
                exists = true;
                break;
            }
        }
        if (!exists) {
            maintainerList[maintainer].push(contractAddr);
        }
    }

    /**
     * @notice 在列表中移除该维持者所维持的合约地址
     * @param maintainer 维持者地址
     * @param contractAddr 所维持心跳的合约地址
     */
    function removeMaintainAddr(address maintainer, address contractAddr) external onlyInstance{
        require(maintainer != address(0), "maintainer addr is 0");
        require(contractAddr != address(0), "contractAddr addr is 0");
        for (uint256 i = 0; i < maintainerList[maintainer].length; ++i) {
            if (maintainerList[maintainer][i] == contractAddr) {
                address last = maintainerList[maintainer][maintainerList[maintainer].length - 1];
                maintainerList[maintainer][i] = last;
                maintainerList[maintainer].pop();
            }
        }
    }

}


