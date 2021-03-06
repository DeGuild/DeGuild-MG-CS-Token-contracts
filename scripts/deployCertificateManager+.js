
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Token1 = await ethers.getContractFactory("CertificateManagerPlus", {
      libraries: {
        ChecksumLib: "0xE951a214ba33B7563FAf307041b31C1224aEf817",
      },
    });
    const token1 = await Token1.deploy();
  
    console.log("New Token address:", token1.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });