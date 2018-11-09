const PixelToken = artifacts.require("./PixelToken.sol");
const ColorToken = artifacts.require("./ColorToken.sol");
const LastPixel = artifacts.require("./LastPixel.sol");

module.exports = function(deployer, network) {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress = ""
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  deployer.deploy(PixelToken, proxyRegistryAddress).then(() => {
    return deployer.deploy(ColorToken, proxyRegistryAddress);
  }).then(() => {
    return deployer.deploy(LastPixel, PixelToken.address, ColorToken.address);
  }).then(async() => {
    var color = await ColorToken.deployed();
    return color.transferOwnership(LastPixel.address);
  }).then(async() => {
    var pixel = await PixelToken.deployed();
    return pixel.transferOwnership(LastPixel.address);
  })
};
