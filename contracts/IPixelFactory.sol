pragma solidity ^0.4.24;

interface PixelFactory {
    function totalSupply() external view returns (uint);
    function ownerOf(uint _tokenId) external view returns (address);
}

