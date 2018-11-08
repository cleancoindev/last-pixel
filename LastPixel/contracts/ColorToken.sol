pragma solidity ^0.4.24;

import './TradeableERC721Token.sol';

contract ColorToken is TradeableERC721Token {
  constructor(address _proxyRegistryAddress) TradeableERC721Token("ColorToken", "CLRT", _proxyRegistryAddress) public {  }
}
