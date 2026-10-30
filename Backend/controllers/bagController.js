
const Fridge = require('../models/fridge');
const Bag = require('../models/bags');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const ErrorHandler = require('../utils/errorHandler');
const Donor = require('../models/donor');
const User = require('../models/user');
const Schedule = require('../models/schedule')
exports.createBag = catchAsyncErrors(async (req, res, next) => {
    const { userID, volume, expressDate, type } = req.body;
    console.log("body: ", req.body)
    const donor = await Donor.findOne({ user: userID });
    if (!donor) {
        return next(new ErrorHandler('Donor not found', 404));
    }
    
    const bags = await Bag.create({ donor: donor._id, volume, expressDate, collectionType: type });
    res.status(201).json({
        success: true,
        bags,
    });
})


exports.getDonorBags = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    const donor = await Donor.find({ user: id });
    if (!donor) {
        return next(new ErrorHandler('Donor not found', 404));
    }
    const result = await Bag.aggregate([
        {
            $match: { donor: donor[0]._id, status: "Expressed" }
        }, // Filter by donor & status
        {
            $group: {
                _id: null,
                totalVolume: { $sum: "$volume" }, // Calculate total volume
                oldestExpressDate: { $min: "$expressDate" }, // Get the earliest expressDate
                latestExpressDate: { $max: "$expressDate" }, // Get the latest expressDate
                bags: {
                    $push: "$$ROOT" // Push all bag documents into an array
                }
            }
        },
        {
            $project: {
                _id: 1,
                totalVolume: 1,
                oldestExpressDate: 1,
                latestExpressDate: 1,
                bags: {
                    $sortArray: { input: "$bags", sortBy: { expressDate: -1 } }
                }
            }
        }
    ]);


    const totalVolume = result.length > 0 ? result[0].totalVolume : 0;
    const bags = result.length > 0 ? result[0].bags : [];
    const oldestExpressDate = result.length > 0 ? result[0].oldestExpressDate : null;
    const latestExpressDate = result.length > 0 ? result[0].latestExpressDate : null;

    res.status(200).json({
        success: true,
        count: bags.length,
        bags,
        totalVolume,
        oldestExpressDate,
        latestExpressDate
    });
})

exports.getSingleBag = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    const bag = await Bag.findById(id);
    if (!bag) {
        return next(new ErrorHandler('Bag not found', 404));
    }
    res.status(200).json({
        success: true,
        bag
    });
})

exports.updateBag = catchAsyncErrors(async (req, res, next) => {
    const { collectionId} = req.body
    const { id } = req.params;
    console.log("update bag body: ", req.body)
    let bag = await Bag.findByIdAndUpdate(id, req.body, {
        new: true,
        runValidators: true,
        useFindAndModify: false
    });
    if (collectionId) {
        
        const schedule = await Schedule.findById(collectionId).populate('donorDetails.bags');
        if (!schedule) {
            return next(new ErrorHandler('Schedule not found', 404));
        }
        const totalVolume = schedule.donorDetails.bags.reduce((acc, curr) => acc + curr.volume || 0, 0);
        await Schedule.findByIdAndUpdate(collectionId, { totalVolume }, { new: true, runValidators: true, useFindAndModify: false });

    }
    if (!bag) {
        return next(new ErrorHandler('Bag not found', 404));
    }
    res.status(200).json({
        success: true,
        bag
    });

})

exports.deleteBag = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    const bag = await Bag.findByIdAndDelete(id);
    if (!bag) {
        return next(new ErrorHandler('Bag not found', 404));
    }
    res.status(200).json({
        success: true,
        message: 'Bag deleted successfully'
    });
})

// Get All Bags => /api/v1/Equipments
exports.allBags = catchAsyncErrors(async (req, res, next) => {
    const allBags = await Bag.find()
        .populate({
            path: "donor",
            select: "user home_address",
            populate: {
                path: "user",
                select: "name"
            }
        });

    const count = await Bag.countDocuments();

    res.status(200).json({
        success: true,
        count,
        allBags
    })
})

exports.updateTemp = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    const bag = await Bag.findById(id);
    if (!bag) {
        return next(new ErrorHandler('Bag not found', 404));
    }

    bag.temp = req.body.temp;
    await bag.save()

    res.status(200).json({
        success: true,
        bag
    });
})