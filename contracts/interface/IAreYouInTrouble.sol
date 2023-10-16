// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IAreYouInTrouble {

    error NotOwnerAccount(address account);
    error NotMaintainerAccount(address account);
    error StakeAmount(address tokenAddr, uint256 amount);
    error InheritorAddressIsZero();
    error ERC20AddressIsZero();
    error ERC721AddressIsZero();
    error InheritedBalanceLack(address caller);
    error inheritanceERC721IDIsNULL(address caller, address ERC721Addr);
    error timeInterval(uint256 lastHeartBeat, uint256 maintainInterval, uint256 curTime);

    event StakedEther(uint256 amount);
    event StakedERC20(address ERC20Addr, uint256 amount);
    event StakedERC721(address ERC721Addr, uint256 tokenID);

    event AddMaintainer(address maintainer, address contractAddr);
    event RemoveMaintainer(address maintainer, address contractAddr);
    event SetInheritanceEther(address inheritor, uint256 inheritanceAmount, address contractAddr, address owner);
    event SetInheritanceERC20(address inheritor, address ERC20Addr, uint256 inheritanceAmount, address contractAddr, address owner);
    event SetInheritanceERC721(address inheritor, address ERC721Addr, uint256[] inheritanceERC721ID, address contractAddr, address owner);


    function initialize(address _owner, address _factoryAddress) external;
}