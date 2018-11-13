pragma solidity ^0.4.24;

import "../utils/ERC721Interfaces.sol";
import "../utils/SupportsInterface.sol";
import "openzeppelin-solidity/ownership/Ownable.sol";

contract PixelBase is Ownable, ERC165, ERC721, ERC721Metadata, ERC721Enumerable, SupportsInterface {
    
    mapping (uint => address) internal tokenApprovals;
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    modifier onlyOwnerOf(uint _tokenId) {
        address owner = _ownerOf[_tokenId];
        require(msg.sender == owner, "Only owner of _tokenId can perfrom this operation...");
        _;
    }

    modifier mustBeOwnedByThisContract(uint _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY, "Provide token id in range [1, 10000]...");
        address owner = _ownerOf[_tokenId];
        require(owner == address(0) || owner == address(this), "Provided token is not owned by this contract...");
        _;
    }

    modifier canOperate(uint _tokenId) {
        address owner = _ownerOf[_tokenId];
        require(msg.sender == owner || operatorApprovals[owner][msg.sender], "You cannot operate with this token...");
        _;
    }

    modifier canTransfer(uint _tokenId) {
        address owner = _ownerOf[_tokenId];
        require(msg.sender == owner ||
        msg.sender == tokenApprovals[_tokenId] ||
        operatorApprovals[owner][msg.sender], "You cannot transfer this token...");
        _;
    }

    modifier isValidToken(uint _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY, "Is not valid token...");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint) {
        require(_owner != address(0), "Owner cannot be equal to address(0)...");
        return _tokensOfOwner[_owner].length;
    }

    function ownerOf(uint _tokenId) external view isValidToken(_tokenId) returns (address _owner)
    {
        _owner = _ownerOf[_tokenId];
        if (_owner == address(0)) {
            _owner = address(this);
        }
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes data) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint _tokenId) external payable isValidToken(_tokenId) canTransfer(_tokenId) {
        address owner = _ownerOf[_tokenId];
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);
    }
    
    // Does not use safe transfer, just for testing purposes
    // TODO - delete this method, since the distribution will happen on OpenSea
    function transfer(uint _tokenId, address _newOwner)
        external
        onlyOwner
        isValidToken(_tokenId)
        mustBeOwnedByThisContract(_tokenId)
    {
        _transfer(_tokenId, _newOwner);
    }
    
    function approve(address _approved, uint _tokenId) external payable canOperate(_tokenId) {
        address _owner = _ownerOf[_tokenId];
        // Do owner address substitution
        if (_owner == address(0)) {
            _owner = address(this);
        }
        tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint _tokenId) external view isValidToken(_tokenId) returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function totalSupply() external view returns (uint) {
        return TOTAL_SUPPLY;
    }

    function tokenByIndex(uint _index) external view returns (uint) {
        require(_index < TOTAL_SUPPLY, "Provide token id in range [1, 10000]...");
        return _index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId) {
        require(_owner != address(0), "Owner does not exist...");
        require(_index < _tokensOfOwner[_owner].length, "Provided address does not own that much tokens...");
        _tokenId = _tokensOfOwner[_owner][_index];
        if (_owner == address(this)) {
            if (_tokenId == 0) {
                _tokenId = _index + 1;
            }
        }
    }
    
    function _transfer(uint _tokenId, address _to) internal {
        require(_to != address(0), "Cannot transfer to address(0)...");

        address from = _ownerOf[_tokenId];
        if (from == address(0)) {
            from = address(this);
        }

        uint indexToDelete = _ownedTokensIndex[_tokenId];
        if (indexToDelete == 0) {
            indexToDelete = _tokenId - 1;
        } else {
            indexToDelete = indexToDelete - 1;
        }
        if (indexToDelete != _tokensOfOwner[from].length - 1) {
            uint lastToken = _tokensOfOwner[from][_tokensOfOwner[from].length - 1];
            if (lastToken == 0) {
                lastToken = _tokensOfOwner[from].length; 
            }
            _tokensOfOwner[from][indexToDelete] = lastToken;
            _ownedTokensIndex[lastToken] = indexToDelete + 1;
        }
        _tokensOfOwner[from].length--;
        _tokensOfOwner[_to].push(_tokenId);
        _ownedTokensIndex[_tokenId] = (_tokensOfOwner[_to].length - 1) + 1;
        _ownerOf[_tokenId] = _to;
        tokenApprovals[_tokenId] = address(0);
        emit Transfer(from, _to, _tokenId);
    }

    uint private constant TOTAL_SUPPLY = 10000;
    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint,bytes)"));

    mapping (uint => address) private _ownerOf;
    mapping (address => uint[]) private _tokensOfOwner;
    mapping (uint => uint) private _ownedTokensIndex;

    constructor() internal {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x8153916a] = true; // ERC721 + 165
        _tokensOfOwner[address(this)].length = TOTAL_SUPPLY;
    }

    function _safeTransferFrom(address _from, address _to, uint _tokenId, bytes data)
        private
        isValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _ownerOf[_tokenId];
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from, "");
        require(_to != address(0), "Cannot transfer to address(0)...");
        _transfer(_tokenId, _to);

        // Do the callback after everything is done to avoid reentrancy attack
        uint codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        require(retval == ERC721_RECEIVED, "");
    }
}

contract Pixel is PixelBase() {
    constructor() public {
    }

    function name() external pure returns (string) {
        return "Pixel";
    }

    function symbol() external pure returns (string) {
        return "PXL";
    }

    function tokenURI(uint _tokenId) external view isValidToken(_tokenId) returns (string _tokenURI) {
        _tokenURI = "tokenURI.json";
    }
}