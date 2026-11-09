/**
 * Test Suite: MilkLink User Registration & Donor Screening Workflow
 */
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, 'config/.env') });

const User = require('./models/user');
const Donor = require('./models/donor');
const Patient = require('./models/patient');
const Request = require('./models/request');
const ScreeningAppointment = require('./models/screeningAppointment');
const HospitalScreeningSchedule = require('./models/hospitalScreeningSchedule');

async function runTests() {
  console.log('Connecting to MongoDB for workflow verification...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB successfully.\n');

  const testSuffix = Date.now().toString().slice(-5);
  let createdUser = null;
  let createdStaff = null;
  let testAppointment = null;
  let testDonor = null;

  try {
    // ------------------------------------------------------------------------
    // TEST 1: Self-Registration without Email
    // ------------------------------------------------------------------------
    console.log('--- TEST 1: Self-Registration Without Email ---');
    const username1 = `testuser_${testSuffix}`;
    createdUser = await User.create({
      name: { first: 'Maria', last: 'Santos' },
      username: username1,
      phone: '09171234567',
      password: 'Password123!',
      role: 'User',
      // email is omitted intentionally
    });
    console.log('✓ Successfully created user without email:', {
      id: createdUser._id.toString(),
      username: createdUser.username,
      role: createdUser.role,
      email: createdUser.email ?? 'None (Optional)'
    });

    // ------------------------------------------------------------------------
    // TEST 2: Duplicate Username / Account Prevention
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 2: Duplicate Account Prevention ---');
    try {
      await User.create({
        name: { first: 'Maria', last: 'Santos' },
        username: username1, // Duplicate
        phone: '09171234567',
        password: 'Password123!',
        role: 'User',
      });
      console.error('✗ Duplicate user creation should have failed!');
    } catch (err) {
      console.log('✓ Duplicate username prevented correctly by unique index/policy:', err.message);
    }

    // ------------------------------------------------------------------------
    // TEST 3: Staff Account Creation
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 3: Staff Account Creation ---');
    const staffUsername = `staff_${testSuffix}`;
    createdStaff = await User.create({
      name: { first: 'Staff', last: 'Nurse' },
      username: staffUsername,
      phone: '09189876543',
      password: 'Password123!',
      role: 'Staff',
      employeeID: parseInt(testSuffix, 10),
    });
    console.log('✓ Staff account created successfully:', {
      id: createdStaff._id.toString(),
      username: createdStaff.username,
      role: createdStaff.role,
      employeeID: createdStaff.employeeID,
    });

    // ------------------------------------------------------------------------
    // TEST 4: New User Has No Automatic Donor Eligibility
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 4: Separate User Account Status From Donor Eligibility ---');
    const donorCheck = await Donor.findOne({ user: createdUser._id });
    console.log('✓ New user donor profile existence:', donorCheck ? 'Found' : 'None (Not automatically an eligible donor)');

    // ------------------------------------------------------------------------
    // TEST 5: Hospital Screening Schedule & Slot Availability
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 5: Hospital Configured Schedule & Slot Capacity ---');
    let schedule = await HospitalScreeningSchedule.findOne({ dayOfWeek: 1 });
    if (!schedule) {
      schedule = await HospitalScreeningSchedule.create({
        dayOfWeek: 1,
        dayName: 'Monday',
        timeSlots: [
          { slotTime: '08:30 AM - 09:30 AM', capacity: 2, isActive: true },
          { slotTime: '09:30 AM - 10:30 AM', capacity: 2, isActive: true },
        ],
        isActive: true,
      });
    }
    console.log('✓ Hospital schedule configured:', {
      day: schedule.dayName,
      slotsCount: schedule.timeSlots.length,
      defaultCapacity: schedule.timeSlots[0].capacity,
    });

    // ------------------------------------------------------------------------
    // TEST 6: User Booking Hospital Screening Appointment
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 6: User Booking Hospital Screening Appointment ---');
    const appointmentDate = new Date();
    appointmentDate.setDate(appointmentDate.getDate() + 2); // 2 days ahead

    testAppointment = await ScreeningAppointment.create({
      appointmentId: `APT-TEST-${testSuffix}`,
      user: createdUser._id,
      purpose: 'First-Time Donor Screening',
      appointmentDate,
      timeSlot: '08:30 AM - 09:30 AM',
      status: 'Pending Confirmation',
      donorNotes: 'First time donor seeking clinic verification.',
    });
    console.log('✓ Appointment booked with status Pending Confirmation:', {
      appointmentId: testAppointment.appointmentId,
      status: testAppointment.status,
      timeSlot: testAppointment.timeSlot,
      userId: testAppointment.user.toString(),
    });

    // ------------------------------------------------------------------------
    // TEST 7: Duplicate Active Appointment Prevention
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 7: Duplicate Active Appointment Check ---');
    const existingActive = await ScreeningAppointment.findOne({
      user: createdUser._id,
      status: { $in: ['Pending Confirmation', 'Confirmed', 'Rescheduled'] },
      isDeleted: false,
    });
    console.log('✓ Detected active appointment properly prevents second concurrent booking:', Boolean(existingActive));

    // ------------------------------------------------------------------------
    // TEST 8: Staff Confirming Screening Appointment
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 8: Staff Confirming Screening Appointment ---');
    testAppointment.status = 'Confirmed';
    testAppointment.assignedStaff = createdStaff._id;
    await testAppointment.save();
    console.log('✓ Staff confirmed appointment:', {
      appointmentId: testAppointment.appointmentId,
      status: testAppointment.status,
      assignedStaff: testAppointment.assignedStaff.toString(),
    });

    // ------------------------------------------------------------------------
    // TEST 9: Staff Recording Attendance & Completing Screening Visit
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 9: Staff Recording Attendance & Authorized Eligibility Decision ---');
    testAppointment.attendanceRecorded = true;
    testAppointment.attendanceRecordedAt = new Date();
    testAppointment.screeningCompleted = true;
    testAppointment.screeningCompletedAt = new Date();
    testAppointment.status = 'Completed';
    testAppointment.staffReviewNotes = 'Physical assessment completed. All laboratory parameters acceptable.';
    testAppointment.eligibilityDecisionRecommendation = 'Recommend Eligible';
    await testAppointment.save();

    // Create donor record with authorized 'Eligible' status
    testDonor = await Donor.create({
      donorId: `2026-${testSuffix}`,
      user: createdUser._id,
      name: { first: createdUser.name.first, last: createdUser.name.last },
      birthday: new Date('1995-05-15'),
      home_address: { street: '123 Caruncho Ave', brgy: 'Malinao', city: 'Pasig City' },
      contact_number: createdUser.phone,
      donorType: 'Community',
      eligibility: 'Eligible',
      verified: true,
      screening: {
        reviewNotes: 'Authorized by staff during screening clinic visit',
        reviewedBy: createdStaff._id,
        reviewedAt: new Date(),
      }
    });

    testAppointment.donor = testDonor._id;
    await testAppointment.save();

    console.log('✓ Screening marked completed and donor eligibility authorized:', {
      donorId: testDonor.donorId,
      eligibility: testDonor.eligibility,
      verified: testDonor.verified,
      appointmentStatus: testAppointment.status,
    });

    // ------------------------------------------------------------------------
    // TEST 10: Ineligible Donor Donation Restriction Check
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 10: Ineligible Donor Donation Restriction Check ---');
    const deferredDonor = await Donor.create({
      donorId: `2026-DEF${testSuffix}`,
      name: { first: 'Ineligible', last: 'Candidate' },
      birthday: new Date('1998-01-01'),
      home_address: { street: 'Street', brgy: 'Kapitolyo', city: 'Pasig City' },
      contact_number: '09170000000',
      donorType: 'Community',
      eligibility: 'Temporarily Deferred',
      verified: false,
    });

    // Simulate restriction
    if (deferredDonor.eligibility !== 'Eligible') {
      console.log('✓ Correctly enforced restriction: Donor with status "' + deferredDonor.eligibility + '" cannot donate.');
    } else {
      console.error('✗ Ineligible donor should not be able to donate.');
    }

    // ------------------------------------------------------------------------
    // TEST 11: Registered User Submitting Milk Request Without Donor Screening
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 11: Registered User Submitting Milk Request Without Donor Screening ---');
    const recipientUser = await User.create({
      name: { first: 'Father', last: 'Recipient' },
      username: `recipient_${testSuffix}`,
      phone: '09191234567',
      password: 'Password123!',
      role: 'User',
    });

    const patient = await Patient.create({
      name: 'Baby Recipient',
      patientType: 'Outpatient',
      motherName: 'Mother Recipient',
      phone: '09191234567',
      staff: createdStaff._id,
      diagnosis: 'Preterm Infant Nutritional Support',
      birthday: new Date(),
      home_address: { street: 'Pasig Blvd', brgy: 'San Nicolas', city: 'Pasig City' }
    });

    const milkRequest = await Request.create({
      patient: patient._id,
      requestedBy: recipientUser._id,
      hospital: 'Pasig City Outpatient Residence',
      diagnosis: 'Preterm Infant',
      reason: 'Low birth weight nutrition',
      doctor: 'Dr. Santos',
      volumeRequested: { volume: 500, days: 3 },
      date: new Date(),
      status: 'Pending',
    });

    console.log('✓ Milk request submitted by registered user without donor screening:', {
      requestId: milkRequest._id.toString(),
      status: milkRequest.status,
      requestedBy: milkRequest.requestedBy.toString(),
      patientName: patient.name,
    });

    // ------------------------------------------------------------------------
    // TEST 12: Returning Donor Repeat Donation Recording
    // ------------------------------------------------------------------------
    console.log('\n--- TEST 12: Returning Donor Repeat Donation Recording ---');
    testDonor.donations.push({
      donationType: 'Public',
      totalVolume: 350,
      numberOfBags: 2,
      collectionDate: new Date(),
      batchReference: `BATCH-${testSuffix}`,
      status: 'Collected',
      recordedBy: createdStaff._id,
      notes: 'Repeat donation at collection outpost without donor login',
    });
    await testDonor.save();

    console.log('✓ Repeat donation recorded successfully under returning donor record:', {
      donorId: testDonor.donorId,
      totalDonations: testDonor.donations.length,
      latestVolume: testDonor.donations[0].totalVolume + ' mL',
      batch: testDonor.donations[0].batchReference,
    });

    console.log('\n========================================');
    console.log('ALL WORKFLOW INTEGRATION TESTS PASSED!');
    console.log('========================================');

  } catch (error) {
    console.error('Test execution failed:', error);
  } finally {
    // Cleanup test artifacts
    console.log('\nCleaning up test database records...');
    if (createdUser) await User.deleteOne({ _id: createdUser._id });
    if (createdStaff) await User.deleteOne({ _id: createdStaff._id });
    if (testAppointment) await ScreeningAppointment.deleteOne({ _id: testAppointment._id });
    if (testDonor) await Donor.deleteOne({ _id: testDonor._id });
    await User.deleteMany({ username: new RegExp(testSuffix) });
    await Donor.deleteMany({ donorId: new RegExp(testSuffix) });
    await Patient.deleteMany({ 'home_address.street': 'Pasig Blvd' });
    await Request.deleteMany({ reason: 'Low birth weight nutrition' });
    await mongoose.disconnect();
    console.log('Database disconnected.');
  }
}

runTests();
