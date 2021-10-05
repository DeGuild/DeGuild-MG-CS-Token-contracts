
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Token1 = await ethers.getContractFactory("CertificateManager0");
    const token1 = await Token1.deploy();
  
    console.log("ICCS101 Token address:", token1.address);

    const Token2 = await ethers.getContractFactory("CertificateManager1");
    const token2 = await Token2.deploy();
  
    console.log("ICCS225 Token address:", token2.address);

    const Token3 = await ethers.getContractFactory("CertificateManager2");
    const token3 = await Token3.deploy();
  
    console.log("ICCS312 Token address:", token3.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });