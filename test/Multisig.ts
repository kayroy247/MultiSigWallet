import { expect } from "chai";
import { keccak256 } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { MultiSig } from "../typechain";
import { Signer } from "ethers";

describe("Multisig", function () {
  let stephen: Signer, keshi, maigida, adamu, moses, multisig: MultiSig;

  before(async function () {
    const [stephen, keshi, maigida, adamu, moses, ...adrs] =
      await ethers.getSigners();
    const Multisig = await ethers.getContractFactory("MultiSig");
    multisig = await Multisig.deploy(
      [
        stephen.address,
        keshi.address,
        maigida.address,
        adamu.address,
        moses.address,
      ],
      3
    );
    await multisig.deployed();
  });

  describe("Submit Transaction", function () {
    it("Check that the number of required approval is 3", async function () {
      expect(await multisig.requiredApprovals()).to.equal(3);
      expect(await multisig.requiredApprovals()).to.not.equal(5);
    });
    it("Submit transaction", async function () {
      const [stephen, keshi, maigida, adamu, moses, ...adrs] =
        await ethers.getSigners();
      await multisig.deployed();
      const saf = await stephen.getAddress();
      await multisig.submit(saf, 1000000, "0xe4332343");
      expect(await multisig.owners(0)).to.be.equal(saf);
    });
  });
});
