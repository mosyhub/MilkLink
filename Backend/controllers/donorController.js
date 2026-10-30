const Donor = require('../models/donor')
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const axios = require('axios');
const User = require('../models/user');
const Bag = require('../models/bags');
const { calculateAge } = require('../utils/helper');
// Get All Donors => /api/v1/donors
exports.allDonors = catchAsyncErrors(async (req, res, next) => {
    // Destructure search query parameters from the request
    const { search, brgy, type } = req.query;

    // Create a query object for Donor
    const query = {};

    // Step 1: Find matching users based on name search
    if (search) {
        const matchingUsers = await User.find({
            $or: [
                { "name.first": { $regex: search, $options: "i" } },
                { "name.middle": { $regex: search, $options: "i" } },
                { "name.last": { $regex: search, $options: "i" } },
            ],
        }).select("_id"); // Get only user IDs

        // If any users match, filter donors by these user IDs
        if (matchingUsers.length > 0) {
            query.user = { $in: matchingUsers.map(user => user._id) };
        } else {
            // If no users match, return an empty result early
            return res.json({ donors: [], total: 0 });
        }
    }

    // Step 2: Apply other filters on Donor
    if (brgy) {
        query["home_address.brgy"] = brgy;
    }
    if (type) {
        query["donorType"] = type;
    }

    // Optional: Add pagination (e.g., limit results and skip for page number)
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.pageSize) || 12; // Adjust page size as needed
    const skip = (page - 1) * pageSize;

    try {

        // Find donors based on the query object
        const donors = await Donor.find(query)
            .populate('donations.milkLettingEvent', 'activity actDetails venue')
            .populate('donations.schedule')
            .populate('user')
            .sort({ 'user.name.first': 1 })

        const totalDonors = await Donor.countDocuments(query);
        const totalPages = Math.ceil(totalDonors / pageSize);

        res.status(200).json({
            success: true,
            totalDonors,
            totalPages,
            pageSize,
            donors
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }

})

exports.predictEligibility = catchAsyncErrors(async (req, res, next) => {
    try {
        console.log("predicting...")
        const bod = req.body;

        if (!bod || !bod.data.fields || !Array.isArray(bod.data.fields)) {
            console.log("no data or fields", data);
            return res.status(400).json({
                success: false,
                message: "Invalid request body. 'fields' array is required."
            });
        }
        const fields = req.body.data.fields;
        let data = {};

        fields.forEach(field => {
            if (field.type === "MULTIPLE_CHOICE") {
                if (field.value !== null) {
                    const result = field.value.map(selected => {
                        const match = field.options.find(option => option.id === selected);
                        return match ? match.text : null;
                    }).filter(item => item !== null);
                    data[field.label] = { label: field.label, value: result };
                }

            }
            else if (field.type === "CHECKBOXES" && field.key === "question_rBK1gL") {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                console.log("result: ", result);
                data[field.label] = { label: field.label, value: result };
            }
            else if (field.type === 'DROPDOWN' && Array.isArray(field.value)) {
                // Find the matching option by ID
                const selectedId = field.value[0]; // assuming single select dropdown
                const selectedOption = field.options.find(option => option.id === selectedId);
                data[field.label] = { label: field.label, value: selectedOption ? selectedOption.text : null }
            }
            else {
                data[field.label] = { label: field.label, value: field.value };
            }

        })

        const relevantQuestions = [
            "Have you donated breast milk before? (Nakapagbigay ka na ba ng iyong gatas dati?)",
            "Will you be allowed by your husband to donate your breast milk to the Taguig City Human Milk Bank? (Papayagan ka ba ng iyong asawa na magbigay ng iyong gatas sa Taguig City Human Milk Bank?)",
            "Have you for any reason been deferred as a milk donor? (Ikaw ba ay natangihan na magbigay ng iyong gatas / breastmilk?)",
            "Did you have a normal pregnancy and delivery for your most recent pregnancy? (Normal ba ang panganganak mo sa huli mong anak?)",
            "Do you have any acute or chronic infection, systemic disorders, tuberculosis or history of hepatitis? (Mayroon ka bang kahit anong impeksyon o sakit? Nagkaroon ng sakit sa atay dati?)",
            "Have you received any blood transfusion or other blood products within the last 12 months? (Ikaw ba ay nasalinan ng dugo o kahit anong produkto mula sa dugo nitong nakaraang 12 buwan?)",
            "Have you received any organ or tissue transplant within the last 12 months? (Ikaw ba ay nakatanggap ng parte ng katawan mula sa ibang tao nitong nakaraang 12 buwan?)",
            "Within the last 24 hours, have you had intake of any hard liquor or alcohol? (Nakainom ka ba ng alak nitong nakaraang 24 oras?)",
            "Do you regularly use over-the-counter medications or systemic preparations such as replacement hormones and some birth control hormones? (Regular ka bang gumagamit ng mga gamot gaya ng mga hormones o pills?)",
            "Do you use megadose vitamins or pharmacologically active herbal preparations? (Gumagamit ka ba ng mga \"megadose vitamins\" o mga \"herbal drugs\"?)",
            "Are you a total vegetarian/vegan? (Ikaw ba ay hindi kumakain ng karne o isang vegetarian?)",
            "Have you had breast augmentation surgery, using silicone breast implants? (Ikaw ba ay naoperahan na sa suso at nalagyan ng “silicone” o artipisyal na breast implants?)",
            "Do you use illicit drugs? (Gumagamit ka ba ng ipinagbabawal na gamot?)",
            "Do you smoke? (Ikaw ba ay naninigarilyo?)",
            "Have you had syphilis, HIV, herpes, or any sexually-transmitted disease? (Nagkakaroon ka ba ng sakit na nakukuha sa pakikipagtalik /sex?)",
            "Do you have multiple sex partners? (Nagkaroon ka ba ng karanasang makipagtalik sa hindi lang iisang lalaki?)",
            "Have you had a sexual partner from any of the following? (Nagkaroon ka ba ng partner mula sa mga sumusunod?)",
            "Have you had a tattoo applied or have had accidental needlestick or contact with someone else's blood? (Nagpalagay ka na ba ng tattoo, naturukan ng karayom nang hindi sinasadya o nadikit sa dugo ng ibang tao?)",
            "Is your child healthy? (Malusog ba ang iyong anak?)",
            "Was your child delivered full term? (Ipinanganak ba ang anak mo na husto sa buwan?)",
            "Are you exclusively breastfeeding your child? (Purong gatas mo ba ang binibigay mo sa anak mo at walang halong ibang formula / gatas?)",
            "Is/Was your youngest child jaundiced? (Madilaw/nanilaw ba ang bunso mong anak?)",
            "Has your child ever received milk from another mother? (Nakatanggap na ba ang iyong anak ng gatas/ breast milk mula sa ibang ina?)"
        ];
        const values = [relevantQuestions.map((key) => {
            // Find the question in the response object that matches the label
            for (const question in data) {
                if (data[question].label === key) {
                    return data[question].value.includes("Yes") || data[question].value.includes("None of the above") ? 1 : 0;
                }
            }
            return null; // Default if not found
        })];


        const json = {
            submissionID: req.body.data.submissionId
        }
        const config = {
            headers: {
                'Content-Type': 'application/json',

            },

        };
        const prediction = await axios.post("https://python-predictive-analysis.onrender.com/predict/", json, config);

        if (!prediction) {
            return res.status(500).json({
                success: false,
                message: "An error occurred while predicting eligibility."
            });
        }

        const result = prediction
        let new_data = {};

        fields.forEach(field => {
            if (field.type === "MULTIPLE_CHOICE" && field.value !== null) {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                new_data[field.label] = result;
            }
            else if (field.type === "CHECKBOXES" && field.key === "question_rBK1gL") {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                console.log("result: ", result);
                new_data[field.label] = result;
            }
            else if (field.type === "DROPDOWN") {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                console.log("result: ", result);
                new_data[field.label] = result[0];
            }
            else {
                new_data[field.label] = field.value;
            }

        })
        const { age, unit } = calculateAge(new_data.child_birthday);
        const children = [{
            name: new_data.child_name,
            age: { value: age, unit: unit },
            birth_weight: new_data.birth_weight,
            aog: new_data.aog
        }];
        let password = `${new_data.first_name.replace(/\s+/g, "").toLowerCase()}${new_data.last_name.replace(/\s+/g, "").toLowerCase()}`;

        const name = {
            first: new_data.first_name || "",
            middle: new_data.middle_name || "",
            last: new_data.last_name || "",
        };

        const userExist = await User.findOne({

            email: new_data.email
        });

        if (userExist) {

            await Donor.findOneAndUpdate({ user: userExist._id }, { submissionID: req.body.data.submissionId, lastSubmissionDate: req.body.createdAt, verified: false }, { new: true });
        }
        else {

            const user = await User.create({
                name: name,
                email: new_data.email,
                phone: new_data.contact_number,
                password: password,
                role: 'User',
            });
            
            await Donor.create({
                user: user._id,
                home_address: {
                    street: new_data.Street,
                    brgy: new_data.brgy,
                    city: new_data.city || 'Taguig City'
                },
                birthday: new_data.birthday,
                children: children,
                office_address: new_data.office_address,
                contact_number: new_data.contact_number_2,
                donorType: new_data.donor_type[0],
                occupation: new_data.occupation,
                eligibility: result.data.prediction,
                submissionID: req.body.data.submissionId,
                lastSubmissionDate: req.body.createdAt
            });

        }
        res.status(200).json({
            success: true,
            
        });


    }
    catch (error) {
        console.error("Error in predicting eligibility:", error);
        res.status(500).json({ error: error.message });
    }
});

exports.testDonors = catchAsyncErrors(async (req, res, next) => {
    try {
        const fields = req.body.data.fields;
        let data = {};
        console.log("fields: ", fields);
        fields.forEach(field => {
            if (field.type === "MULTIPLE_CHOICE" && field.value !== null) {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                data[field.label] = result;
            }
            else if (field.type === "CHECKBOXES" && field.key === "question_rBK1gL") {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                console.log("result: ", result);
                data[field.label] = result;
            }
            else if (field.type === "DROPDOWN") {
                const result = field.value.map(selected => {
                    const match = field.options.find(option => option.id === selected);
                    return match ? match.text : null;
                }).filter(item => item !== null);
                console.log("result: ", result);
                data[field.label] = result[0];
            }
            else {
                data[field.label] = field.value;
            }

        })
        console.log("data: ", data);

        // Prepare children array with one child object
        const children = [{
            name: data.child_name,
            age: data.child_age,
            birth_weight: data.birth_weight,
            aog: data.aog
        }];
        let password = `${data.first_name.replace(/\s+/g, "").toLowerCase()}${data.last_name.replace(/\s+/g, "").toLowerCase()}`;

        const name = {
            first: data.first_name || "",
            middle: data.middle_name || "",
            last: data.last_name || "",
        };

        const userExist = await User.findOne({
            name,
            email: data.email
        });

        if (userExist) {
            return res.status(400).json({
                success: false,
                message: "User already exists"
            });
        }

        const user = await User.create({
            name: name,
            email: data.email,
            phone: data.contact_number,
            password: password,
            role: 'User',
        });
        // Create donor in the database
        const donor = await Donor.create({
            user: user._id,
            home_address: {
                street: data.Street,
                brgy: data.brgy,
                city: data.city || 'Taguig City'
            },
            age: data.age,
            birthday: data.birthday,
            children: children,
            office_address: data.office_address,
            contact_number: data.contact_number_2,
            donorType: data.donor_type[0],
            occupation: data.occupation
        });

        console.log("data: ", data);
        res.status(200).json({
            success: true,
            fields,
            data,
            donor
        });
    }
    catch (error) {
        console.error("Error in createDonor:", error);
        res.status(500).json({ error: error.message });
    }
})
// Create donor => /api/v1/donors
exports.createDonor = catchAsyncErrors(async (req, res, next) => {
    try {
        const data = req.body;

        if (!data || !data.data.fields || !Array.isArray(data.data.fields)) {
            console.log("no data or fields", data);
            return res.status(400).json({
                success: false,
                message: "Invalid request body. 'fields' array is required."
            });
        }

        const fields = data.data.fields;
        // Extract the child name
        const childName = fields[11]?.value;

        // Prepare children array with one child object
        const children = childName ? [{ name: childName }] : [];
        console.log("checkbox: ", fields.find(field => field.key === "question_rBK1gL"));
        console.log("checkbox options: ", fields.find(field => field.key === "question_rBK1gL").options);
        // Validate required fields
        if (fields.length < 12) {
            console.log("fields length", fields.length);
            return res.status(400).json({
                success: false,
                message: "Incomplete form submission. Please provide all required fields."
            });
        }

        const name = {
            first: fields[0]?.value || "",
            middle: fields[1]?.value || "",
            last: fields[2]?.value || "",
        };

        // Check for missing required field values
        if (!name.first || !name.last || !fields[6]?.value || !fields[7]?.value || !fields[4]?.value || !fields[3]?.value) {
            return res.status(400).json({
                success: false,
                message: "Missing required fields: first name, last name, address, phone, age, or birthday."
            });
        }

        // Create donor in the database
        const donor = await Donor.create({
            name: name,
            home_address: fields[6].value,
            phone: fields[7].value,
            age: fields[4].value,
            birthday: fields[3].value,
            children: children,
        });

        res.status(201).json({
            success: true,
            donor,
        });
    } catch (error) {
        console.error("Error in createDonor:", error);

        res.status(500).json({
            success: false,
            message: "An error occurred while creating the donor.",
            error: error.message,
        });
    }
});

// Get specific donor details => /api/v1/donor/:id
exports.getDonorDetails = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findById(req.params.id)
        .populate('donations.milkLettingEvent', 'activity actDetails venue attendance')
        .populate('donations.schedule')
        .populate('user');

    if (!donor) {
        return next(new ErrorHandler(`donor is not found with this id: ${req.params.id}`));
    }

    for (const donation of donor.donations) {
        const mle = donation.milkLettingEvent;

        if (!mle || !Array.isArray(mle.attendance)) continue;

        let totalVolume = 0;


        if (mle?.attendance) {
            const myAttendance = mle.attendance.find(att => att.donor._id.toString() === donor._id.toString())
            if (myAttendance) {
                // Use only necessary donor fields to avoid circular reference
                myAttendance.donor = {
                    _id: donor._id,
                    name: donor.name, // or any fields you need
                };

                myAttendance.bags = await Bag.find({ _id: { $in: myAttendance.bags } });
                myAttendance.additionalBags = await Bag.find({ _id: { $in: myAttendance.additionalBags } });
                const totalBags = myAttendance.bags.reduce((acc, bag) => acc + bag.volume, 0)
                const totalAdditionalBags = myAttendance.additionalBags.reduce((acc, bag) => acc + bag.volume, 0);
                totalVolume = totalBags + totalAdditionalBags;
                mle.attendance = [myAttendance];
            } else {
                mle.attendance = [];
            }

        }

        // Add totalVolume directly to the donation object
        donation.totalVolume = totalVolume;
    }
    console.log("donor: ", donor);
    res.status(200).json({
        success: true,
        donor,
    });

})

// Get Logged-in Donor Profile => /api/v1/donor/me
exports.getMyDonorProfile = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findOne({ user: req.user.id })
        .populate('donations.milkLettingEvent', 'activity actDetails venue attendance')
        .populate('donations.schedule')
        .populate('user');

    if (!donor) {
        return res.status(200).json({
            success: true,
            hasDonorProfile: false,
            donor: null
        });
    }

    for (const donation of donor.donations) {
        const mle = donation.milkLettingEvent;
        if (!mle || !Array.isArray(mle.attendance)) continue;

        let totalVolume = 0;
        if (mle?.attendance) {
            const myAttendance = mle.attendance.find(att => att.donor._id.toString() === donor._id.toString());
            if (myAttendance) {
                myAttendance.donor = {
                    _id: donor._id,
                    name: donor.name,
                };
                myAttendance.bags = await Bag.find({ _id: { $in: myAttendance.bags } });
                myAttendance.additionalBags = await Bag.find({ _id: { $in: myAttendance.additionalBags } });
                const totalBags = myAttendance.bags.reduce((acc, bag) => acc + bag.volume, 0);
                const totalAdditionalBags = myAttendance.additionalBags.reduce((acc, bag) => acc + bag.volume, 0);
                totalVolume = totalBags + totalAdditionalBags;
                mle.attendance = [myAttendance];
            } else {
                mle.attendance = [];
            }
        }
        donation.totalVolume = totalVolume;
    }

    res.status(200).json({
        success: true,
        hasDonorProfile: true,
        donor,
    });
});

// Update donor => /api/v1/donor/:id
exports.updateDonor = catchAsyncErrors(async (req, res, next) => {
    console.log("Update Donor: ", req.body)
    const donor = await Donor.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    res.status(200).json({
        success: true,
        donor
    })

})

// Delete donor => /api/v1/donor/:id
exports.deleteDonor = catchAsyncErrors(async (req, res, next) => {
    const donor = await Donor.findById(req.params.id);

    if (!donor) {
        return next(new ErrorHandler(`Donor is not found with this id: ${req.params.id}`))
    }

    await donor.deleteOne();

    res.status(200).json({
        success: true,
        message: "Donor Deleted"
    })
})

exports.checkEligibility = catchAsyncErrors(async (req, res, next) => {
    const id = req.params.id;

    const donor = await Donor.find({ submissionID: id })
    if (donor.length === 0) {
        return res.status(404).json({
            success: false,
            message: "Donor not found"
        })
    }
    res.status(200).json({
        success: true,
        message: "Donor found",
        donor
    })
})

exports.getNewSubmissions = catchAsyncErrors(async (req, res, next) => {
    try {
        const donors = await Donor.find({ verified: false })
            .populate({
                path: 'user',
                select: 'name'
            });
        if (!donors || donors.length === 0) {
            return res.status(201).json({
                success: false,
                message: "No new submissions found."
            });
        }
        res.status(200).json({
            success: true,
            message: "New submissions found.",
            donors
        })


    } catch (error) {
        res.status(500).json({
            success: false,
            message: "An error occurred while fetching submissions.",
            error: error.message,
        });
    }
})