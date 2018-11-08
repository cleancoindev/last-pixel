pragma solidity ^0.4.24;

import './TradeableERC721Token.sol';

contract PixelToken is TradeableERC721Token {
  constructor(address _proxyRegistryAddress) TradeableERC721Token("PixelToken", "PXLT", _proxyRegistryAddress) public {  }
}
