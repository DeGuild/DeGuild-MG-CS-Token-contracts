const { expect } = require("chai");

describe("Token contract", function () {
  it("Deployment should not assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("DeGuildCoin");

    const DeGuildCoin = await Token.deploy();

    const ownerBalance = await DeGuildCoin.balanceOf(owner.address);
    expect(DeGuildCoin.totalSupply()).to.equal(ownerBalance);
  });

  it("Deployment should be named DeGuild Coin", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("DeGuildCoin");

    const DeGuildCoin = await Token.deploy();

    expect(await DeGuildCoin.name()).to.equal("DeGuild Coin");
  });

  it("Deployment should be symbolized DGC", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("DeGuildCoin");

    const DeGuildCoin = await Token.deploy();

    expect(await DeGuildCoin.symbol()).to.equal("DGC");
  });
});