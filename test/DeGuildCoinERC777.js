const { expect } = require("chai");

describe("Deguild Coin ERC777-contract", function () {

  beforeEach(async function () {
    this.SushiToken = await ethers.getContractFactory("DeGuildCoinERC777");

    [registryFunder, ...addrs] = await ethers.getSigners();

    this.sushi = await this.SushiToken.deploy()
    await this.sushi.deployed()
  })


  it("should have correct name and symbol and decimal", async function () {
    const name = await this.sushi.name()
    const symbol = await this.sushi.symbol()
    expect(name, "SushiToken")
    expect(symbol, "SUSHI")
  })
});