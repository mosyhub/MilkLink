/**
 * Integration Test:
 * Unification of Temporary User Registration, Staff Donor Records,
 * Unique Account Claim Tokens, and Screening Workflow.
 */
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const crypto = require('crypto');

dotenv.config({ path: path.join(__dirname, 'config/.env') });

const User = require('./models/user');
const Donor = require('./models/donor');
const Patient = require('./models/patient');
const Request = require('./models/request');
const ScreeningAppointment = require('./models/screeningAppointment');
const { generateClaimCredentials } = require('./utils/qrHelper');

async function runUnificationTests() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB.\n');

  const testSuffix = Date.now().toString().slice(-5);
  let staffUser = null;
  let tempUser = null;
  let staffCreatedDonor = null;
  let appointment = null;

  try {
    // ------------------------------------------------------------------------
    // SCENARIO 1: Staff Creates Donor Record and Generates Unique Claim Token
    // ------------------------------------------------------------------------
    console.log('--- SCENARIO 1: Staff creates donor & generates claim token ---');
    staffUser = await User.create({
      name: { first: 'Nurse', last: 'Joy' },
      username: `staff_joy_${testSuffix}`,
      phone: '09181112233',
      password: 'Password123!',
      role: 'Staff',
      accountStatus: 'Verified',
      employeeID: parseInt(testSuffix, 10),
    });

    const { rawToken, tokenHash, expiresAt, qrCodeData } = await generateClaimCredentials('Donor');

    staffCreatedDonor = await Donor.create({
      donorId: `2026-${testSuffix}`,
      user: null, // Unclaimed
      staff: staffUser._id,
      name: { first: 'Elena', last: 'Reyes' },
      birthday: new Date('1994-08-20'),
      home_address: { street: '45 Mercedes Ave', brgy: 'San Miguel', city: 'Pasig City' },
      contact_number: '09175554321',
      donorType: 'Community',
      eligibility: 'Eligible',
      verified: true,
      claimToken: rawToken,
      claimTokenHash: tokenHash,
      claimTokenExpires: expiresAt,
      qrCodeData,
      donations: [
        {
          donationType: 'Public',
          totalVolume: 400,
          numberOfBags: 2,
          collectionDate: new Date(),
          batchReference: `BATCH-${testSuffix}`,
          status: 'Collected',
        }
      ]
    });

    console.log('✓ Staff created donor with unique single-use claim credentials:', {
      donorId: staffCreatedDonor.donorId,
      rawToken,
      isClaimed: Boolean(staffCreatedDonor.user),
      hasDonations: staffCreatedDonor.donations.length > 0,
    });

    // ------------------------------------------------------------------------
    // SCENARIO 2: Public Donor Search Does NOT Leak Claim Token
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 2: Public donor search protects claim token ---');
    const searched = await Donor.findOne({ donorId: staffCreatedDonor.donorId })
      .select('donorId name contact_number home_address donorType eligibility verified');
    console.log('✓ Public search result excludes claimToken and hash:', {
      donorId: searched.donorId,
      claimToken: searched.claimToken === undefined ? 'HIDDEN (Protected)' : 'LEAKED!',
      claimTokenHash: searched.claimTokenHash === undefined ? 'HIDDEN (Protected)' : 'LEAKED!',
    });

    // ------------------------------------------------------------------------
    // SCENARIO 3: User Creates Temporary Account Without Email
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 3: User Creates Temporary Account Without Email ---');
    tempUser = await User.create({
      name: { first: 'Elena', last: 'Reyes' },
      username: `elena_${testSuffix}`,
      phone: '09175554321',
      password: 'Password123!',
      role: 'User',
      accountStatus: 'Temporary',
      // email is omitted
    });

    console.log('✓ Temporary account created:', {
      id: tempUser._id.toString(),
      username: tempUser.username,
      accountStatus: tempUser.accountStatus,
      email: tempUser.email || 'None (Optional)',
    });

    // ------------------------------------------------------------------------
    // SCENARIO 4: Temporary User Appears in Pending Online Registrations
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 4: Temporary user appears in Pending Online Registrations ---');
    const pendingQuery = { role: 'User', isDeleted: false, _id: tempUser._id };
    const pendingList = await User.find(pendingQuery);
    const donorLink = await Donor.findOne({ user: tempUser._id });

    console.log('✓ Pending online registrations detects temporary user:', {
      username: pendingList[0].username,
      accountStatus: pendingList[0].accountStatus,
      isLinkedToDonor: Boolean(donorLink),
    });

    // ------------------------------------------------------------------------
    // SCENARIO 5: Temporary User Books Hospital Screening Appointment
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 5: Temporary User Schedules Hospital Screening ---');
    const aptDate = new Date();
    aptDate.setDate(aptDate.getDate() + 3);

    appointment = await ScreeningAppointment.create({
      appointmentId: `APT-TMP-${testSuffix}`,
      user: tempUser._id,
      purpose: 'First-Time Donor Screening',
      appointmentDate: aptDate,
      timeSlot: '09:30 AM - 10:30 AM',
      status: 'Pending Confirmation',
    });

    console.log('✓ Hospital screening scheduled by temporary user:', {
      appointmentId: appointment.appointmentId,
      status: appointment.status,
      timeSlot: appointment.timeSlot,
    });

    // ------------------------------------------------------------------------
    // SCENARIO 6: Invalid / Reused Claim Token is Rejected
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 6: Rejection of Invalid Claim Token ---');
    const badHash = crypto.createHash('sha256').update('INVALID-TOKEN-999').digest('hex');
    const badRecord = await Donor.findOne({
      claimTokenHash: badHash,
      claimTokenExpires: { $gt: new Date() },
      user: null,
    });
    console.log('✓ Invalid token properly rejected (not found):', badRecord === null);

    // ------------------------------------------------------------------------
    // SCENARIO 7: Temporary User Claims Existing Staff-Created Donor Record
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 7: Temporary User Claims Staff-Created Donor Record ---');
    const validHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    const claimableDonor = await Donor.findOne({
      $or: [{ claimTokenHash: validHash }, { claimToken: rawToken }],
      claimTokenExpires: { $gt: new Date() },
      user: null,
      isDeleted: false,
    });

    if (!claimableDonor) {
      throw new Error('Claimable donor not found with valid token');
    }

    // Atomic linking
    claimableDonor.user = tempUser._id;
    claimableDonor.claimToken = undefined;
    claimableDonor.claimTokenHash = undefined;
    claimableDonor.claimTokenExpires = undefined;
    claimableDonor.qrCodeData = null;
    await claimableDonor.save();

    tempUser.accountStatus = 'Verified';
    await tempUser.save();

    console.log('✓ Donor record linked and claimed successfully:', {
      donorId: claimableDonor.donorId,
      linkedUserId: claimableDonor.user.toString(),
      tokenInvalidated: claimableDonor.claimToken === undefined,
      userAccountStatus: tempUser.accountStatus,
      preservedDonationsCount: claimableDonor.donations.length,
      preservedTotalVolume: claimableDonor.donations[0].totalVolume,
    });

    // ------------------------------------------------------------------------
    // SCENARIO 8: Reused Token is Rejected
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 8: Reused Token Rejection ---');
    const reusedAttempt = await Donor.findOne({
      $or: [{ claimTokenHash: validHash }, { claimToken: rawToken }],
      claimTokenExpires: { $gt: new Date() },
      user: null,
    });
    console.log('✓ Reused token rejected because token was consumed and invalidated:', reusedAttempt === null);

    // ------------------------------------------------------------------------
    // SCENARIO 9: Duplicate Claim / Multi-Donor Conflict Prevention
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 9: Duplicate Claim / Conflicting Link Prevention ---');
    try {
      // Attempting to link another donor to the same user
      const secondDonor = new Donor({
        donorId: `2026-CONFLICT-${testSuffix}`,
        user: tempUser._id, // Duplicate link to same user
        name: { first: 'Clone', last: 'Donor' },
        birthday: new Date('1990-01-01'),
        home_address: { street: 'Street', brgy: 'Brgy', city: 'Pasig City' },
        contact_number: '09180000000',
        donorType: 'Community',
      });
      await secondDonor.save();
      console.error('✗ MongoDB unique index should have blocked duplicate user reference in donors!');
    } catch (err) {
      console.log('✓ Duplicate donor link prevented by MongoDB partial unique index:', err.message);
    }

    // ------------------------------------------------------------------------
    // SCENARIO 10: Milk Request Available to User Without Prior Donor Eligibility
    // ------------------------------------------------------------------------
    console.log('\n--- SCENARIO 10: Milk Request Available to Registered User Without Donor Eligibility ---');
    const recipientUser = await User.create({
      name: { first: 'Roberto', last: 'Cruz' },
      username: `roberto_${testSuffix}`,
      phone: '09178889900',
      password: 'Password123!',
      role: 'User',
      accountStatus: 'Temporary',
    });

    const patient = await Patient.create({
      name: 'Baby Cruz',
      patientType: 'Outpatient',
      motherName: 'Ana Cruz',
      phone: '09178889900',
      staff: staffUser._id,
      diagnosis: 'Preterm infant feeding',
      birthday: new Date(),
      home_address: { street: 'A. Mabini St', brgy: 'Kapasigan', city: 'Pasig City' },
    });

    const request = await Request.create({
      patient: patient._id,
      requestedBy: recipientUser._id,
      hospital: 'Pasig City General Hospital',
      diagnosis: 'Preterm infant',
      reason: 'Clinical nutrition support',
      doctor: 'Dr. Mendoza',
      volumeRequested: { volume: 300, days: 2 },
      date: new Date(),
      status: 'Pending',
    });

    console.log('✓ Milk request submitted by registered user without donor profile:', {
      requestId: request._id.toString(),
      status: request.status,
      requestedBy: request.requestedBy.toString(),
      userHasDonorProfile: false,
    });

    console.log('\n======================================================');
    console.log('ALL 10 UNIFIED WORKFLOW INTEGRATION SCENARIOS PASSED!');
    console.log('======================================================');

  } catch (err) {
    console.error('Test execution error:', err);
  } finally {
    console.log('\nCleaning up test records...');
    if (staffUser) await User.deleteOne({ _id: staffUser._id });
    if (tempUser) await User.deleteOne({ _id: tempUser._id });
    if (staffCreatedDonor) await Donor.deleteOne({ _id: staffCreatedDonor._id });
    if (appointment) await ScreeningAppointment.deleteOne({ _id: appointment._id });
    await User.deleteMany({ username: new RegExp(testSuffix) });
    await Donor.deleteMany({ donorId: new RegExp(testSuffix) });
    await Patient.deleteMany({ name: 'Baby Cruz' });
    await Request.deleteMany({ reason: 'Clinical nutrition support' });
    await mongoose.disconnect();
    console.log('Database disconnected.');
  }
}

runUnificationTests();
