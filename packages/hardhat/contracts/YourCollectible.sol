// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract YourCollectible is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    address KEEPER_CONTRACT_ADDRESS;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _sudoOwner;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _timedOwner;


    constructor(address keeperContractAddress) ERC721("YourCollectible", "YCB") {
            // inject keeper address
            KEEPER_CONTRACT_ADDRESS = keeperContractAddress;

    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }


    function mintItem(address to, string memory uri) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // new code, set the sudo owner to the minter 
        _sudoOwner[tokenId] = to;
        // new token, set the timed owner to 0
        _timedOwner[tokenId] = address(0);
        
        return tokenId;
    }

    /**
     * Override the ERC721
     * Only the sudo owner can perform approve operation
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address currentOwner = ERC721.ownerOf(tokenId);
        require(to != currentOwner, "ERC721: approval to current owner");

        // new code
        address sudoOwner = _sudoOwner[tokenId];
        
        require(
            sudoOwner == _msgSender() || isApprovedForAll(sudoOwner, _msgSender()),
            "ERC721: approve caller is not sudo owner nor approved for all"
        );

        _approve(to, tokenId);
    }


     /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender || spender == KEEPER_CONTRACT_ADDRESS);
    }


    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // new code. only the sudo owner can do tranfer 
        require(from == _sudoOwner[tokenId] ||  _msgSender() == KEEPER_CONTRACT_ADDRESS, "ERC721: the from address is not the sudo owner");
        // new code. sudo owner can't transfer if there's a timed owner if the sender is not keeper
        require(_timedOwner[tokenId] == address(0) ||  _msgSender() == KEEPER_CONTRACT_ADDRESS, "ERC721: token currently has timed owner");
        
        super.transferFrom(from, to, tokenId);
         
         // new code update the sudo owner
         _sudoOwner[tokenId] = to;
         // new code: reset the timed owner
         _timedOwner[tokenId] = address(0);
         // nee code: 
    }

     function timedTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 expireTime
    ) public virtual{
        // new code. only the sudo owner can do timed tranfer 
        require(from == _sudoOwner[tokenId], "ERC721: the from address is not the cool sudo owner");
        
        // new code. sudo owner can't transfer if there's a timed owner
        require(_timedOwner[tokenId] == address(0), "ERC721: token currently has timed owner");
     
        transferFrom(from, to, tokenId);
        
        // new code, set the timed owner to the new owner
        _timedOwner[tokenId] = to;
        // new code update the sudo owner back
        _sudoOwner[tokenId] = from;

        // new code, schedule a keeper
        console.log("sweet let's schedule a keeper");
        KeeperContract keeperContract = KeeperContract(KEEPER_CONTRACT_ADDRESS);
        keeperContract.addRentData(from, to, tokenId, address(this), block.timestamp, expireTime);
        console.log("add rent data is done");
    }


    /**
     * @dev See {IERC721-ownerOf}.
     */
    function sudoOwnerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _sudoOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function timedOwnerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _timedOwner[tokenId];
        require(owner != address(0), "ERC721: there's no timed owner currently");
        return owner;
    }

    /////// The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /////// The above functions are overrides required by Solidity.

}


interface KeeperContract {
    function addRentData(
        address owner, 
        address renter, 
        uint256 tokenId, 
        address contractAddress, 
        uint startDate,  
        uint endDate
        ) external;
}