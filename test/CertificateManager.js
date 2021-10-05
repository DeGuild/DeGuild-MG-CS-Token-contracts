const { expect } = require("chai");

describe("Certificate Manager Contract", function () {
  
  before(async function () {
    this.Certificate = await ethers.getContractFactory("CertificateManager1")
    this.signers = await ethers.getSigners()
  })

  beforeEach(async function () {
    this.CertificateManager = await this.Certificate.deploy()
    await this.CertificateManager.deployed()
  })


  it("should have correct name and symbol and decimal", async function () {
    const name = await this.CertificateManager.name()
    const symbol = await this.CertificateManager.symbol()
    // const uri = await this.CertificateManager.
    const address = await this.CertificateManager.tokenURI()
    console.log(address)
    expect(name, "Introduction to Computer Programming")
    expect(symbol, "ICCS101")
  })

});