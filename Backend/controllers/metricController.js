const ErrorHandler = require("../utils/errorHandler");
const catchAsyncErrors = require("../middlewares/catchAsyncErrors");
const Inventory = require("../models/inventory");
const Fridge = require("../models/fridge");
const Donor = require("../models/donor");
const Recipient = require("../models/patient");
const Bags = require("../models/bags");
const Patient = require("../models/patient");
const Request = require("../models/request");

exports.getMetrics = catchAsyncErrors(async (req, res) => {
  try {
    const totalBags = await Inventory.countDocuments();
    const totalFridges = await Fridge.countDocuments();
    const totalDonors = await Donor.countDocuments();
    const totalRecipients = await Recipient.countDocuments();

    res.status(200).json({
      success: true,
      metrics: {
        totalBags,
        totalFridges,
        totalDonors,
        totalRecipients,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

exports.getDonorsPerMonth = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);
    const donors = await Donor.find({ createdAt: { $gte: startDate, $lte: endDate } });
    const monthlyData = {};

    donors.forEach((donor) => {
      const isCommunity = donor.donorType === "Community";
      const isPrivate = [
        "Private",
        "Employee",
        "Network Office/Agency",
      ].includes(donor.donorType);

      if (!isCommunity && !isPrivate) return;

      const month = new Date(donor.createdAt).toLocaleString("default", {
        month: "long",
      });

      if (!monthlyData[month]) {
        monthlyData[month] = { community: 0, private: 0, total: 0 };
      }

      if (isCommunity) {
        monthlyData[month].community++;
      } else if (isPrivate) {
        monthlyData[month].private++;
      }

      monthlyData[month].total++;
    });

    const yearlyTotals = { community: 0, private: 0, total: 0 };
    Object.values(monthlyData).forEach((monthStats) => {
      yearlyTotals.community += monthStats.community;
      yearlyTotals.private += monthStats.private;
      yearlyTotals.total += monthStats.total;
    });

    monthlyData["total"] = yearlyTotals;

    const result = monthlyData;

    res.status(200).json({
      success: true,
      result,
    });
  } catch (error) {
    console.error("Error fetching donor counts:", error);
    res.status(500).json({
      message: "Server error, please try again later.",
    });
  }
});

exports.getDonationStats = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);
    const bags = await Bags.find({ status: ["Collected", "Pasteurized"], createdAt: { $gte: startDate, $lte: endDate } });

    const stats = {};

    bags.forEach((bag) => {
      const isCommunity = bag.collectionType === "Public";
      const isPrivate = bag.collectionType === "Private";

      if (!isCommunity && !isPrivate) return;

      const month = new Date(bag.createdAt).toLocaleString("default", {
        month: "long",
      });

      const volume = bag.volume;

      if (!stats[month]) {
        stats[month] = { community: 0, private: 0, total: 0 };
      }

      if (isCommunity) {
        stats[month].community += volume;
      } else if (isPrivate) {
        stats[month].private += volume;
      }

      stats[month].total += volume;
    });

    const yearlyTotals = { community: 0, private: 0, total: 0 };
    Object.values(stats).forEach((monthStats) => {
      yearlyTotals.community += monthStats.community;
      yearlyTotals.private += monthStats.private;
      yearlyTotals.total += monthStats.total;
    });

    stats["total"] = yearlyTotals;

    res.status(200).json({
      success: true,
      stats,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

exports.getDispensedMilk = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);

    console.log("Start Date:", startDate.toISOString());
    console.log("End Date:", endDate.toISOString());
    const requests = await Request.find({ status: "Done", "tchmb.dispenseAt": { $gte: startDate, $lt: endDate } });

    const stats = {};

    requests.forEach((request) => {
      const isOutpatient = request.type === "Outpatient";
      const isInpatient = request.type === "Inpatient";

      if (!isOutpatient && !isInpatient) return;

      const rawDate = request.tchmb.dispenseAt;
      const parsedDate = new Date(rawDate);
      let month = "";
      if (!isNaN(parsedDate)) {
        month = parsedDate.toLocaleString("default", { month: "long" });
        // proceed to use `month` in your grouping logic
      } else {
        console.warn("Invalid date encountered:", rawDate);
        // optionally skip this entry or put it in a separate error log
      }

      const volume = request.tchmb.ebm
        .map((item) => item.volDischarge || 0)
        .reduce((sum, vol) => sum + vol, 0);

      if (!stats[month]) {
        stats[month] = { outpatient: 0, inpatient: 0, total: 0 };
      }

      if (isOutpatient) {
        stats[month].outpatient += volume;
      } else if (isInpatient) {
        stats[month].inpatient += volume;
      }

      stats[month].total += volume;
    });

    const yearlyTotals = { outpatient: 0, inpatient: 0, total: 0 };
    Object.values(stats).forEach((monthStats) => {
      yearlyTotals.outpatient += monthStats.outpatient;
      yearlyTotals.inpatient += monthStats.inpatient;
      yearlyTotals.total += monthStats.total;
    });

    stats["total"] = yearlyTotals;

    res.status(200).json({
      success: true,
      dispensedMilk: stats,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

exports.getPatientsPerMonth = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);
    const patients = await Patient.find({ createdAt: { $gte: startDate, $lte: endDate } });
    const monthlyData = {};

    patients.forEach((patient) => {
      const isOutpatient = patient.patientType === "Outpatient";
      const isInpatient = patient.patientType === "Inpatient";

      if (!isOutpatient && !isInpatient) return;

      const month = new Date(patient.createdAt).toLocaleString("default", {
        month: "long",
      });

      if (!monthlyData[month]) {
        monthlyData[month] = { outpatient: 0, inpatient: 0, total: 0 };
      }

      if (isOutpatient) {
        monthlyData[month].outpatient++;
      } else if (isInpatient) {
        monthlyData[month].inpatient++;
      }

      monthlyData[month].total++;
    });

    const yearlyTotals = { outpatient: 0, inpatient: 0, total: 0 };
    Object.values(monthlyData).forEach((monthStats) => {
      yearlyTotals.outpatient += monthStats.outpatient;
      yearlyTotals.inpatient += monthStats.inpatient;
      yearlyTotals.total += monthStats.total;
    });

    monthlyData["total"] = yearlyTotals;

    const result = monthlyData;

    res.status(200).json({
      success: true,
      recipients: result,
    });
  } catch (error) {
    console.error("Error fetching request recipients counts:", error);
    res.status(500).json({
      message: "Server error, please try again later.",
    });
  }
});

exports.getRequestsPerMonth = catchAsyncErrors(async (req, res, next) => {
  try {
    const requests = await Request.find();
    const incomingRequests = requests.filter((req) => req.status === "Pending");
    const completedRequests = requests.filter((req) => req.status === "Done");
    console.log(requests)

    const monthlyData = {};

    requests.forEach((req) => {
      const isOutpatient = req.type === "Outpatient";
      const isInpatient = req.type === "Inpatient";

      if (!isOutpatient && !isInpatient) return;

      const month = new Date(req.date).toLocaleString("default", {
        month: "long",
      });

      if (!monthlyData[month]) {
        monthlyData[month] = { outpatient: 0, inpatient: 0, total: 0 };
      }

      if (isOutpatient) {
        monthlyData[month].outpatient++;
      } else if (isInpatient) {
        monthlyData[month].inpatient++;
      }

      monthlyData[month].total++;
    });

    const yearlyTotals = { outpatient: 0, inpatient: 0, total: 0 };
    Object.values(monthlyData).forEach((monthStats) => {
      yearlyTotals.outpatient += monthStats.outpatient;
      yearlyTotals.inpatient += monthStats.inpatient;
      yearlyTotals.total += monthStats.total;
    });

    monthlyData["total"] = yearlyTotals;
    monthlyData["pending"] = incomingRequests.length;
    monthlyData["completed"] = completedRequests.length;
    const result = monthlyData;

    res.status(200).json({
      success: true,
      requests: result,
    });
  } catch (error) {
    console.error("Error fetching request recipients counts:", error);
    res.status(500).json({
      message: "Server error, please try again later.",
    });
  }
});

exports.getAvailableMilk = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);
    const fridges = await Fridge.find();
    let totalVolume = 0;
    const past = fridges.filter((f) => f.fridgeType === 'Pasteurized') || []


    let pastFridge = []

    if (past.length > 0) {
      pastFridge = await Promise.all(past.map(async (fridge) => {
        const inventories = await Inventory.find({ fridge: fridge._id, status: "Available", "pasteurizedDetails.pasteurizationDate": { $gte: startDate, $lte: endDate } })
          .populate({
            path: "pasteurizedDetails.donors",
            populate: {
              path: "user",
              select: "name"
            }
          })
          .sort({ 'pasteurizedDetails.pasteurizationDate': 1 })
        // Return fridge object with totalVolume included
        return {
          inventories
        };
      }));
    }

    pastFridge[0].inventories.forEach((inventory) => {
      if (inventory.status === "Available") {
        const details = inventory.pasteurizedDetails;
        const bottleVolume = details.bottleType; // volume per bottle in mL

        const availableBottlesCount = details.bottles.filter(
          (bottle) => bottle.status === "Available"
        ).length;

        totalVolume += availableBottlesCount * bottleVolume;
      }
    });



    res.status(200).json({
      success: true,
      count: pastFridge[0].inventories.length,
      availableMilk: totalVolume
    });
  } catch (error) {
    console.error('Error fetching fridges:', error);
    res.status(500).json({
      success: false,
      message: error.message
    })
  }
})

exports.pasteurizeSoon = catchAsyncErrors(async (req, res, next) => {
  try {
    const fridges = await Fridge.find();
    let totalVolume = 0;
    const unpast = fridges.filter((f) => f.fridgeType === 'Unpasteurized') || []


    let unpastFridge = []

    if (unpast.length > 0) {
      unpastFridge = await Promise.all(unpast.map(async (fridge) => {
        const inventories = await Inventory.find({ fridge: fridge._id })
          .populate({
            path: "unpasteurizedDetails.collectionId",
            populate: [{
              path: "pubDetails",
              populate: [
                {
                  path: "attendance.donor",
                  populate: {
                    path: "user",
                    select: "name email phone"
                  },
                  select: "_id home_address"
                },
                {
                  path: "attendance.bags",
                  select: "volume status"
                },
                {
                  path: "attendance.additionalBags",
                  select: "volume status"
                }
              ]
            },
            {
              path: 'privDetails',
              populate: [{
                path: "donorDetails.donorId",
              },
              {
                path: "donorDetails.bags",
                select: "volume status"
              }]
            }]
          });
        if (inventories.length > 0) {
          const allBags = inventories.flatMap(inv => {
            const attendanceBags = inv?.unpasteurizedDetails?.collectionId?.pubDetails?.attendance?.flatMap(att => [
              ...(att.bags || []),
              ...(att.additionalBags || [])
            ]) || [];

            const donorBags = inv?.unpasteurizedDetails?.collectionId?.privDetails?.donorDetails?.bags || [];

            return [...attendanceBags, ...donorBags];
          });
          totalVolume = allBags
            .filter(bag => bag.status !== "Pasteurized") // Exclude "Pasteurized" bags
            .reduce((acc, bag) => acc + (bag.volume || 0), 0); // Sum up the volume

        }
        // Return fridge object with totalVolume included
        return {
          ...fridge.toObject(), // Convert Mongoose object to plain object
          totalVolume
        };
      }));


    }

    const availableMilk = unpastFridge.reduce((acc, fridge) => acc + fridge.totalVolume, 0);
    res.status(200).json({
      success: true,
      count: unpastFridge.length,
      expiringMilk: availableMilk
    });
  } catch (error) {
    console.error('Error fetching fridges:', error);
    res.status(500).json({
      success: false,
      message: error.message
    })
  }
})

exports.getDonationLocations = catchAsyncErrors(async (req, res, next) => {
  try {
    const allBags = await Bags.find({ status: ["Collected", "Pasteurized"] })
      .populate({
        path: "donor",
        select: "user home_address",
        populate: {
          path: "user",
          select: "name"
        }
      });
    const count = await Bags.countDocuments();

    const cityGroups = {}; // { mainKeyword: { name: fullCityName, totalVolume: number } }

    const normalizeCity = (rawCity = '') => {
      let normalized = rawCity.trim().toLowerCase();
      normalized = normalized.replace(/\b(city|municipality)\b/g, '').trim();
      return normalized.split(' ')[0]; // main keyword (e.g., "taguig")
    };

    allBags.forEach(bag => {
      const rawCity = bag?.donor?.home_address?.brgy || 'Unknown';
      const volume = bag.volume || 0;
      const mainKeyword = normalizeCity(rawCity);
      const fullNormalizedCity = rawCity.trim().toLowerCase();

      if (!cityGroups[mainKeyword]) {
        cityGroups[mainKeyword] = {
          name: fullNormalizedCity,
          totalVolume: 0
        };
      }

      // Use the longest/most descriptive name as the label
      if (fullNormalizedCity.length > cityGroups[mainKeyword].name.length) {
        cityGroups[mainKeyword].name = fullNormalizedCity;
      }

      cityGroups[mainKeyword].totalVolume += volume;
    });

    // Build the final result
    const result = {};
    let grandTotal = 0;

    Object.values(cityGroups).forEach(group => {
      result[group.name] = group.totalVolume;
      grandTotal += group.totalVolume;
    });

    result.total = grandTotal;
    const volumePerLocation = result;
    res.status(200).json({
      success: true,
      count,
      volumePerLocation
    })
  } catch (error) {
    console.error('Error fetching donation locations:', error);
    res.status(500).json({
      success: false,
      message: error.message
    })
  }
})

exports.getDonorLocations = catchAsyncErrors(async (req, res, next) => {
  try {
    const donors = await Donor.find();

    const brgyMap = new Map();
    let total = 0;

    donors.forEach((donor) => {
      const originalBrgy = donor.home_address?.brgy || '';
      const normalizedBrgy = originalBrgy
        .toLowerCase()
        .replace(/^brgy[.\s]*/i, '') // remove "brgy.", "brgy ", "brgy. " prefix
        .trim();

      if (!normalizedBrgy) return;

      total += 1;

      if (!brgyMap.has(normalizedBrgy)) {
        brgyMap.set(normalizedBrgy, {
          count: 1,
          originalNames: [originalBrgy],
        });
      } else {
        const entry = brgyMap.get(normalizedBrgy);
        entry.count += 1;
        entry.originalNames.push(originalBrgy);
      }
    });

    const groupedResult = {};

    for (const [normalized, { count, originalNames }] of brgyMap.entries()) {
      const finalBrgyName = originalNames.reduce((a, b) =>
        a.length >= b.length ? a : b
      );
      groupedResult[finalBrgyName] = count;
    }

    // Add total at the end
    groupedResult.total = total;

    res.status(200).json({
      success: true,
      donors: groupedResult
    })

  } catch (error) {
    console.error('Error fetching donor locations:', error);
    res.status(500).json({
      success: false,
      message: error.message
    })
  }
})

exports.getPatientHospitals = catchAsyncErrors(async (req, res, next) => {
  try {
    const requests = await Request.find();
    const hospitalMap = {};

    requests.forEach((request) => {
      let hospitalKey;

      if (request.department) {
        // If department exists, group under TPDH
        hospitalKey = "TPDH";
      } else if (request.hospital) {
        hospitalKey = request.hospital;
      } else {
        hospitalKey = "Unknown";
      }

      // Initialize or increment count
      if (!hospitalMap[hospitalKey]) {
        hospitalMap[hospitalKey] = 1;
      } else {
        hospitalMap[hospitalKey]++;
      }
    });

    // Optionally, compute total
    const total = Object.values(hospitalMap).reduce((sum, val) => sum + val, 0);
    hospitalMap.total = total;

    res.status(200).json({
      success: true,
      hospitals: hospitalMap
    })
  } catch (error) {
    console.error('Error fetching patient hospitals:', error);
    res.status(500).json({
      success: false,
      message: error.message
    })
  }
})

exports.getPasteurizedMilkPerMonth = catchAsyncErrors(async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear(); // Get the year from query parameters
    // Start and end of the year
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);
    const fridges = await Fridge.find();
    const past = fridges.filter((f) => f.fridgeType === 'Pasteurized') || [];

    let pastFridge = [];

    if (past.length > 0) {
      pastFridge = await Promise.all(past.map(async (fridge) => {
        const inventories = await Inventory.find({ fridge: fridge._id, status: "Available", "pasteurizedDetails.pasteurizationDate": { $gte: startDate, $lte: endDate } })
          .populate({
            path: "pasteurizedDetails.donors",
            populate: {
              path: "user",
              select: "name"
            }
          })
          .sort({ 'pasteurizedDetails.pasteurizationDate': 1 });

        return { inventories };
      }));
    }

    // Initialize monthly volume tracker
    const totalVolumeByMonth = {};

    for (const fridge of pastFridge) {
      for (const inventory of fridge.inventories) {
        const details = inventory.pasteurizedDetails;
        const bottleVolume = details.bottleType; // mL per bottle

        const pasteurizationDate = details.pasteurizationDate;
        if (!pasteurizationDate) continue;


        const parsedDate = new Date(pasteurizationDate);
        let month = "";
        if (!isNaN(parsedDate)) {
          month = parsedDate.toLocaleString("default", { month: "long" });
          // proceed to use `month` in your grouping logic
        } else {
          console.warn("Invalid date encountered:", pasteurizationDate);
          // optionally skip this entry or put it in a separate error log
        }


        const availableBottles = details.bottles.filter(
          (b) => b.status === "Available"
        );

        const volume = availableBottles.length * bottleVolume;

        if (!totalVolumeByMonth[month]) {
          totalVolumeByMonth[month] = 0;
        }

        totalVolumeByMonth[month] += volume;
      }
    }
    const yearlyTotals = { total: 0 };
    Object.values(totalVolumeByMonth).forEach((monthStats) => {
      yearlyTotals.total += monthStats;
    });

    totalVolumeByMonth["total"] = yearlyTotals;
    res.status(200).json({
      success: true,
      monthlyVolumes: totalVolumeByMonth
    });

  } catch (error) {
    console.error('Error fetching fridges:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
})

exports.getDonorAge = catchAsyncErrors(async (req, res, next) => {
  const today = new Date();

  const donorAgeDemographics = await Donor.aggregate([
    {
      $addFields: {
        age: {
          $dateDiff: {
            startDate: "$birthday",
            endDate: today,
            unit: "year"
          }
        }
      }
    },
    {
      $group: {
        _id: "$age",
        count: { $sum: 1 }
      }
    },
    {
      $sort: { _id: 1 } // optional: sort by age
    }
  ]);

  // Initialize age range counters
  const ageRanges = {
    "Below 16": 0,
    "17-20": 0,
    "21-35": 0,
    "36-50": 0,
    "Above 50": 0
  };

  let total = 0;

  // Categorize ages into ranges
  donorAgeDemographics.forEach(item => {
    const age = item._id;
    const count = item.count;

    if (age < 16) {
      ageRanges["Below 16"] += count;
    } else if (age >= 17 && age <= 20) {
      ageRanges["17-20"] += count;
    } else if (age >= 21 && age <= 35) {
      ageRanges["21-35"] += count;
    } else if (age >= 36 && age <= 50) {
      ageRanges["36-50"] += count;
    } else if (age > 50) {
      ageRanges["Above 50"] += count;
    }

    total += count;
  });

  // Add total to the response
  ageRanges.total = total;

  res.status(200).json({
    success: true,
    donorAge: ageRanges
  });
});