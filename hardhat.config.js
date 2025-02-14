require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); 

HOLESKY_RPC_URL = "https://ethereum-holesky-rpc.publicnode.com"
PRIVATE_KEY = "a79158b5c20182f1aa21012af895e72cf13748bda9123a4c50ac48a72ed1541c"

module.exports = {
  solidity: "0.8.20",
  networks: {
    holesky: {
      url: process.env.HOLESKY_RPC_URL || "", 
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], 
    },
  },
  etherscan: {
    apiKey: "6335G8RBWT6FBGEX5F3JT1UBYEP77C2J15"  // You'll need to get this from Etherscan
  }
};