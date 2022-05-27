//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Keepers is KeeperCompatibleInterface {
  event CheckUpkeep(uint blockTimeStamp, uint lastTimeStamp);
  event PerformUpkeep(uint lastTimeStamp, uint counter);
  
  event AddRentalData(address owner, address renter, uint256 tokenId, address contactAddress, uint startDate,  uint endDate);
  event CheckEndRent(address owner, address renter, uint256 tokenId, address contactAddress, uint startDate,  uint endDate);
  event NeedEndRent(address owner, address renter, uint256 tokenId, address contactAddress, uint startDate,  uint endDate);
  event SuccessEndRent(address owner, address renter, uint256 tokenId, address contactAddress, uint startDate,  uint endDate);
  
  event TransferToRenter(address owner, address renter, uint256 tokenId);

  uint public lastTimeStamp;
  uint public counter;
  uint public currentRentalCount;

  struct RentalData {
    address owner;
    address renter;
    uint256 tokenId;
    address contractAddress;
    uint startDate;
    uint endDate;
    bool hasReturned ; 
  }

  RentalData[] public rentalDatas;
  
  constructor() public {
    lastTimeStamp = block.timestamp;
    counter = 0;
    currentRentalCount = 0;
  }
  
  function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
      upkeepNeeded = false;
      for (uint i = 0; i < rentalDatas.length; i++) {             
        if(block.timestamp > rentalDatas[i].endDate && rentalDatas[i].hasReturned == false) {
          upkeepNeeded = true;
        } 
      }    
   }

   function performUpkeep(bytes calldata performData) external override{
      for (uint i = 0; i < rentalDatas.length; i++) {             
          if(block.timestamp > rentalDatas[i].endDate && rentalDatas[i].hasReturned == false) {
              // transfer token from current owner back to sudo owner
              console.log("Found something needs to transfer");
              TargetContract c = TargetContract(rentalDatas[i].contractAddress);
              c.transferFrom(rentalDatas[i].renter, rentalDatas[i].owner, rentalDatas[i].tokenId);
              rentalDatas[i].hasReturned = true;
              console.log("tranfer is done"); 
        } 
      } 
   }

   // add rent data
   function addRentData(address owner, address renter, uint256 tokenId, 
      address contractAddress, uint startDate,  uint endDate) public {
        emit AddRentalData(owner, renter, tokenId, contractAddress, startDate, endDate);
        rentalDatas.push(RentalData(owner, renter, tokenId, contractAddress, startDate, endDate, false));
   }


  // test function to show current rent data
  function getRentData() public {
    currentRentalCount = rentalDatas.length;
    string memory temp = "";
    console.log(rentalDatas.length);
    for (uint i = 0; i < rentalDatas.length; i++) {
      temp = string(abi.encodePacked("Contract: ", addressToString(rentalDatas[i].contractAddress), 
         "/Owner: ", addressToString(rentalDatas[i].owner), 
         "/Renter: ", addressToString(rentalDatas[i].renter), 
         "/TokenId: ", Strings.toString(rentalDatas[i].tokenId),
         "/ExpireTime: ", Strings.toString(rentalDatas[i].endDate)));
         console.log(temp);
      } 
  }

  function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(51);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

}

interface TargetContract {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

