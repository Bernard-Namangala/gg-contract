const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("GreenGiraffeTracibility", function () {
  let gg;
  let owner;
  let addr1;
  let addr2;

  // Sample data for testing
  const sampleBatch = {
    batchId: "B00001",
    cropName: "Rice",
    start: Math.floor(Date.now() / 1000),
    end: Math.floor(Date.now() / 1000) + 7776000, // 90 days later
    farmer: "John Doe",
    expectedYield: 1000,
    land: "Field A",
    status: "Active",
  };

  const sampleActivity = {
    batchId: "B00001",
    activityName: "Planting",
    start: {
      date: Math.floor(Date.now() / 1000),
      hour: 8,
      minute: 30,
    },
    end: {
      date: Math.floor(Date.now() / 1000),
      hour: 16,
      minute: 30,
    },
    areaCovered: 100,
  };

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const GG = await ethers.getContractFactory("GreenGiraffeTracibility");
    gg = await GG.deploy();
  });

  describe("Batch Operations", function () {
    it("Should create a new batch", async function () {
      const tx = await gg.createBatch(sampleBatch);
      await expect(tx)
        .to.emit(gg, "BatchCreated")
        .withArgs(
          sampleBatch.batchId,
          sampleBatch.cropName,
          sampleBatch.start,
          sampleBatch.end,
          sampleBatch.farmer,
          sampleBatch.expectedYield,
          sampleBatch.land,
          sampleBatch.status,
          BigInt(await time.latest())
        );
    });

    it("Should fail to create batch with empty fields", async function () {
      const invalidBatch = { ...sampleBatch, cropName: "" };
      await expect(gg.createBatch(invalidBatch)).to.be.revertedWithCustomError(
        gg,
        "EmptyRequiredField"
      );
    });

    it("Should deactivate a batch", async function () {
      await gg.createBatch(sampleBatch);
      await expect(gg.deactivateBatch(sampleBatch.batchId))
        .to.emit(gg, "BatchUpdated")
        .withArgs(sampleBatch.batchId, "Cancelled");
    });
  });

  describe("Activity Log Operations", function () {
    beforeEach(async function () {
      await gg.createBatch(sampleBatch);
    });

    it("Should create an activity log", async function () {
      await expect(gg.createActivityLog(sampleActivity)).to.emit(
        gg,
        "ActivityLogCreated"
      );
    });

    it("Should fail for invalid time range", async function () {
      const invalidActivity = {
        ...sampleActivity,
        start: { ...sampleActivity.start, hour: 16 },
        end: { ...sampleActivity.end, hour: 8 },
      };
      await expect(
        gg.createActivityLog(invalidActivity)
      ).to.be.revertedWithCustomError(gg, "InvalidTimeRange");
    });
  });

  describe("Access Control", function () {
    it("Should fail when non-owner tries to create batch", async function () {
      await expect(
        gg.connect(addr1).createBatch(sampleBatch)
      ).to.be.revertedWithCustomError(gg, "OwnableUnauthorizedAccount");
    });

    it("Should allow operator to pause contract", async function () {
      await gg.connect(owner).setOperator(addr1.address, true);
      await expect(gg.connect(addr1).pause()).to.not.be.reverted;
    });
  });

  describe("Data Validation", function () {
    it("Should validate batch time range", async function () {
      const invalidBatch = {
        ...sampleBatch,
        start: sampleBatch.end,
        end: sampleBatch.start,
      };
      await expect(gg.createBatch(invalidBatch)).to.be.revertedWithCustomError(
        gg,
        "InvalidTimeRange"
      );
    });

    it("Should validate activity time components", async function () {
      await gg.createBatch(sampleBatch);

      const invalidActivity = {
        ...sampleActivity,
        start: { ...sampleActivity.start, hour: 24 },
      };
      await expect(
        gg.createActivityLog(invalidActivity)
      ).to.be.revertedWithCustomError(gg, "InvalidTimeRange");
    });
  });

  describe("Sustainability Log Operations", function () {
    const sampleSustainability = {
      batchId: "B00001",
      practiceName: "Organic Fertilizer",
      implementationDate: Math.floor(Date.now() / 1000),
      impactDescription: "Reduced chemical usage by 50%",
      areaCovered: 100,
    };

    beforeEach(async function () {
      await gg.createBatch(sampleBatch);
    });

    it("Should create a sustainability log", async function () {
      const tx = await gg.createSustainabilityLog(sampleSustainability);
      await expect(tx)
        .to.emit(gg, "SustainabilityLogCreated")
        .withArgs(
          0, // First log ID
          sampleSustainability.batchId,
          sampleSustainability.practiceName,
          sampleSustainability.implementationDate,
          sampleSustainability.impactDescription,
          sampleSustainability.areaCovered,
          BigInt(await time.latest()) // Use BigInt for timestamp
        );

      // Verify the log was created
      const log = await gg.sustainabilityLogs(0);
      expect(log.batchId).to.equal(sampleSustainability.batchId);
      expect(log.practiceName).to.equal(sampleSustainability.practiceName);
      expect(log.impactDescription).to.equal(
        sampleSustainability.impactDescription
      );
      expect(log.areaCovered).to.equal(sampleSustainability.areaCovered);
    });

    it("Should fail with empty practice name", async function () {
      const invalidLog = {
        ...sampleSustainability,
        practiceName: "",
      };
      await expect(
        gg.createSustainabilityLog(invalidLog)
      ).to.be.revertedWithCustomError(gg, "EmptyRequiredField");
    });

    it("Should fail with empty impact description", async function () {
      const invalidLog = {
        ...sampleSustainability,
        impactDescription: "",
      };
      await expect(
        gg.createSustainabilityLog(invalidLog)
      ).to.be.revertedWithCustomError(gg, "EmptyRequiredField");
    });

    it("Should fail with invalid area covered", async function () {
      const invalidLog = {
        ...sampleSustainability,
        areaCovered: 0,
      };
      await expect(
        gg.createSustainabilityLog(invalidLog)
      ).to.be.revertedWithCustomError(gg, "InvalidAreaCovered");
    });

    it("Should fail with future implementation date", async function () {
      const invalidLog = {
        ...sampleSustainability,
        implementationDate: Math.floor(Date.now() / 1000) + 86400, // Tomorrow
      };
      await expect(
        gg.createSustainabilityLog(invalidLog)
      ).to.be.revertedWithCustomError(gg, "InvalidDate");
    });
  });
});
