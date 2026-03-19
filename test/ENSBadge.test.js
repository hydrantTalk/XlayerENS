import hre from "hardhat";
import { expect } from "chai";

describe("ENSBadge", function () {
  let ensBadge;
  let owner, user1, user2;
  let ethers;
  let MINT_PRICE;

  before(async function () {
    const connection = await hre.network.connect();
    ethers = connection.ethers;
    MINT_PRICE = ethers.parseEther("0.1");
  });

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const ENSBadge = await ethers.getContractFactory("ENSBadge");
    ensBadge = await ENSBadge.deploy(owner.address);
    await ensBadge.waitForDeployment();
  });

  describe("Constructor", function () {
    it("should pre-mint Badge #1 to owner", async function () {
      expect(await ensBadge.ownerOf(1)).to.equal(owner.address);
      expect(await ensBadge.hasMinted(owner.address)).to.equal(true);
      expect(await ensBadge.badgeOf(owner.address)).to.equal(1);
    });

    it("should set correct name and symbol", async function () {
      expect(await ensBadge.name()).to.equal("Agentic Wallet ENS Badge");
      expect(await ensBadge.symbol()).to.equal("ENSBADGE");
    });

    it("should set totalMinted to 1", async function () {
      expect(await ensBadge.totalMinted()).to.equal(1);
    });
  });

  describe("Mint - EOA rejection", function () {
    it("should reject direct EOA calls", async function () {
      await expect(
        ensBadge.connect(user1).mint({ value: MINT_PRICE })
      ).to.be.revertedWith("ENSBadge: only smart contract wallets allowed");
    });
  });

  describe("Mint - via contract (simulated)", function () {
    let minterContract;

    beforeEach(async function () {
      const MinterHelper = await ethers.getContractFactory("MinterHelper");
      minterContract = await MinterHelper.deploy();
      await minterContract.waitForDeployment();
    });

    it("should mint successfully from a contract wallet", async function () {
      await minterContract.doMint(await ensBadge.getAddress(), { value: MINT_PRICE });
      const minterAddr = await minterContract.getAddress();

      expect(await ensBadge.hasMinted(minterAddr)).to.equal(true);
      expect(await ensBadge.badgeOf(minterAddr)).to.equal(2);
      expect(await ensBadge.ownerOf(2)).to.equal(minterAddr);
      expect(await ensBadge.totalMinted()).to.equal(2);
    });

    it("should reject duplicate mint from same contract", async function () {
      await minterContract.doMint(await ensBadge.getAddress(), { value: MINT_PRICE });
      await expect(
        minterContract.doMint(await ensBadge.getAddress(), { value: MINT_PRICE })
      ).to.be.revertedWith("ENSBadge: already minted");
    });

    it("should reject insufficient payment", async function () {
      await expect(
        minterContract.doMint(await ensBadge.getAddress(), { value: ethers.parseEther("0.05") })
      ).to.be.revertedWith("ENSBadge: insufficient payment (need 0.1 OKB)");
    });

    it("should forward mint fee to owner", async function () {
      // Use user1 to fund the minter so owner balance only changes from fee receipt
      await user1.sendTransaction({ to: await minterContract.getAddress(), value: MINT_PRICE });
      const ownerBalBefore = await ethers.provider.getBalance(owner.address);
      await minterContract.connect(user1).doMint(await ensBadge.getAddress(), { value: MINT_PRICE });
      const ownerBalAfter = await ethers.provider.getBalance(owner.address);
      expect(ownerBalAfter - ownerBalBefore).to.equal(MINT_PRICE);
    });

    it("should auto-increment badge numbers", async function () {
      const MinterHelper = await ethers.getContractFactory("MinterHelper");
      const minter2 = await MinterHelper.deploy();
      await minter2.waitForDeployment();

      await minterContract.doMint(await ensBadge.getAddress(), { value: MINT_PRICE });
      await minter2.doMint(await ensBadge.getAddress(), { value: MINT_PRICE });

      expect(await ensBadge.badgeOf(await minterContract.getAddress())).to.equal(2);
      expect(await ensBadge.badgeOf(await minter2.getAddress())).to.equal(3);
      expect(await ensBadge.totalMinted()).to.equal(3);
    });
  });

  describe("getBadgeInfo", function () {
    it("should return correct info for badge holder", async function () {
      const [hasBadge, badgeNumber, totalMinted] = await ensBadge.getBadgeInfo(owner.address);
      expect(hasBadge).to.equal(true);
      expect(badgeNumber).to.equal(1);
      expect(totalMinted).to.equal(1);
    });

    it("should return false for non-holder", async function () {
      const [hasBadge, badgeNumber, totalMinted] = await ensBadge.getBadgeInfo(user1.address);
      expect(hasBadge).to.equal(false);
      expect(badgeNumber).to.equal(0);
      expect(totalMinted).to.equal(1);
    });
  });

  describe("getBadgeNumber", function () {
    it("should return tokenId as badge number", async function () {
      expect(await ensBadge.getBadgeNumber(1)).to.equal(1);
      expect(await ensBadge.getBadgeNumber(42)).to.equal(42);
    });
  });

  describe("tokenURI", function () {
    it("should return valid base64 data URI", async function () {
      const uri = await ensBadge.tokenURI(1);
      expect(uri).to.match(/^data:application\/json;base64,/);
    });

    it("should contain agent instructions in metadata", async function () {
      const uri = await ensBadge.tokenURI(1);
      const json = Buffer.from(uri.split(",")[1], "base64").toString();
      const metadata = JSON.parse(json);

      expect(metadata.name).to.equal("Agentic Wallet ENS Badge #1");
      expect(metadata.description).to.include("AGENT INSTRUCTIONS");
      expect(metadata.description).to.include("Badge #1");
      expect(metadata.agent_info).to.exist;
      expect(metadata.agent_info.contract_type).to.equal("ENSBadge");
      expect(metadata.agent_info.chain_id).to.equal(196);
      expect(metadata.agent_info.purpose).to.equal("Agentic Wallet Identity Badge");
    });

    it("should contain valid SVG image", async function () {
      const uri = await ensBadge.tokenURI(1);
      const json = Buffer.from(uri.split(",")[1], "base64").toString();
      const metadata = JSON.parse(json);

      expect(metadata.image).to.match(/^data:image\/svg\+xml;base64,/);
      const svg = Buffer.from(metadata.image.split(",")[1], "base64").toString();
      expect(svg).to.include("<svg");
      expect(svg).to.include("#1");
    });

    it("should revert for non-existent token", async function () {
      await expect(ensBadge.tokenURI(999)).to.be.revert(ethers);
    });
  });

  describe("contractURI", function () {
    it("should return valid collection metadata", async function () {
      const uri = await ensBadge.contractURI();
      expect(uri).to.match(/^data:application\/json;base64,/);
      const json = Buffer.from(uri.split(",")[1], "base64").toString();
      const metadata = JSON.parse(json);
      expect(metadata.name).to.equal("Agentic Wallet ENS Badges");
      expect(metadata.description).to.include("AGENT PROTOCOL");
    });
  });

  describe("supportsInterface (ERC-165)", function () {
    it("should support ERC-721", async function () {
      expect(await ensBadge.supportsInterface("0x80ac58cd")).to.equal(true);
    });

    it("should support ERC-165", async function () {
      expect(await ensBadge.supportsInterface("0x01ffc9a7")).to.equal(true);
    });

    it("should support IENSBadge", async function () {
      const iface = new ethers.Interface([
        "function mint() external payable",
        "function getBadgeInfo(address) external view returns (bool, uint256, uint256)",
        "function getBadgeNumber(uint256) external pure returns (uint256)",
        "function totalMinted() external view returns (uint256)",
        "function MINT_PRICE() external view returns (uint256)",
      ]);
      const selectors = [
        iface.getFunction("mint").selector,
        iface.getFunction("getBadgeInfo").selector,
        iface.getFunction("getBadgeNumber").selector,
        iface.getFunction("totalMinted").selector,
        iface.getFunction("MINT_PRICE").selector,
      ];
      let interfaceId = 0n;
      for (const sel of selectors) {
        interfaceId ^= BigInt(sel);
      }
      const interfaceIdHex = "0x" + interfaceId.toString(16).padStart(8, "0");

      expect(await ensBadge.supportsInterface(interfaceIdHex)).to.equal(true);
    });
  });

  describe("Transfer", function () {
    it("should allow transfer (not soulbound)", async function () {
      await ensBadge.connect(owner).transferFrom(owner.address, user1.address, 1);
      expect(await ensBadge.ownerOf(1)).to.equal(user1.address);
    });
  });

  describe("MINT_PRICE", function () {
    it("should return 0.1 ether", async function () {
      expect(await ensBadge.MINT_PRICE()).to.equal(MINT_PRICE);
    });
  });
});
