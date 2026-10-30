const express = require("express");
const router = express.Router();

const { isAuthenticatedUser, authorizeRoles } = require("../middlewares/auth");
const {
  getMetrics,
  getDonationStats,
  getDonorsPerMonth,
  getDispensedMilk,
  getPatientsPerMonth,
  getRequestsPerMonth,
  getAvailableMilk,
  pasteurizeSoon,
  getDonationLocations,
  getDonorLocations,
  getPatientHospitals,
  getPasteurizedMilkPerMonth,
  getDonorAge,
} = require("../controllers/metricController");

router.route("/metrics")
  .get(isAuthenticatedUser, authorizeRoles("SuperAdmin", "Admin"), getMetrics);

router.route("/milkPerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDonationStats
  );
router.route("/donorsPerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDonorsPerMonth
  );
router.route("/dispensePerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDispensedMilk
  );
router.route("/pasteurizedMilkPerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getPasteurizedMilkPerMonth
  );
router.route("/patientsPerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getPatientsPerMonth
  );
router.route("/requestsPerMonth")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getRequestsPerMonth
  );

router.route("/availableMilk")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getAvailableMilk
  );

router.route("/expiringMilk")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    pasteurizeSoon
  );

router.route("/donationLocation")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDonationLocations
  );

router.route("/donorLocation")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDonorLocations
  );

router.route("/patientHospital")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getPatientHospitals
  );

router.route("/donorAge")
  .get(
    isAuthenticatedUser,
    authorizeRoles("SuperAdmin", "Admin"),
    getDonorAge
  )
module.exports = router;
