const Fridge = require('../models/fridge')
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const Inventory = require('../models/inventory');
// Get All fridges => /api/v1/fridges
exports.allFridges = catchAsyncErrors(async (req, res) => {
    try {
        const fridges = await Fridge.find();
        let totalVolume = 0;
        const past = fridges.filter((f) => f.fridgeType === 'Pasteurized') || []
        const unpast = fridges.filter((f) => f.fridgeType === 'Unpasteurized') || []
        let unpastFridge = [];
        let pastFridge = []
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
        if (past.length > 0) {
            pastFridge = await Promise.all(past.map(async (fridge) => {
                const inventories = await Inventory.find({ fridge: fridge._id, status: "Available" })
                    .populate({
                        path: "pasteurizedDetails.donors",
                        populate: {
                            path: "user",
                            select: "name"
                        }
                    })
                    .sort({ 'pasteurizedDetails.pasteurizationDate': 1 })
                let availableMilk = 0;
                inventories.forEach((inventory) => {
                    if (inventory.status === "Available") {
                        const details = inventory.pasteurizedDetails;
                        const bottleVolume = details.bottleType; // volume per bottle in mL

                        const availableBottlesCount = details.bottles.filter(
                            (bottle) => bottle.status === "Available"
                        ).length;

                        availableMilk += availableBottlesCount * bottleVolume;
                    }
                });
                // Return fridge object with totalVolume included
                return {
                    ...fridge.toObject(),
                    inventories,
                    availableMilk
                };
            }));
        }


        const updatedFridges = [...unpastFridge, ...pastFridge]
        res.status(200).json({
            success: true,
            count: updatedFridges.length,
            fridges: updatedFridges,
            
        });
    } catch (error) {
        console.error('Error fetching fridges:', error);
        res.status(500).json({
            success: false,
            message: error.message
        })
    }




})

// Create fridge => /api/v1/fridges
exports.createFridge = catchAsyncErrors(async (req, res) => {
    const data = req.body;

    const fridge = await Fridge.create({
        name: data.name,
        fridgeType: data.fridgeType.trim(),
    });

    res.status(201).json({
        success: true,
        fridge
    });
})

// Get specific fridge details => /api/v1/fridge/:id
exports.getFridgeDetails = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.findById(req.params.id);

    if (!fridge) {
        return next(new ErrorHandler(`fridge is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        fridge
    })
})

// Update fridge => /api/v1/fridge/:id
exports.updateFridge = catchAsyncErrors(async (req, res, next) => {
    const data = req.body;

    const newfridgeData = {
        name: data.name,
        fridgeType: data.fridgeType.trim(),
    }

    const fridge = await Fridge.findByIdAndUpdate(req.params.id, newfridgeData, {
        new: true,
        runValidators: true,
        useFindAndModify: false,
    })

    if (!fridge) {
        return next(new ErrorHandler(`fridge is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        fridge
    })

})

// Delete fridge => /api/v1/fridge/:id
exports.deleteFridge = catchAsyncErrors(async (req, res, next) => {
    const fridge = await Fridge.findById(req.params.id);

    if (!fridge) {
        return next(new ErrorHandler(`fridge is not found with this id: ${req.params.id}`))
    }

    await fridge.deleteOne();

    res.status(200).json({
        success: true,
        message: "Fridge Deleted"
    })
})


exports.openFridge = catchAsyncErrors(async (req, res, next) => {
    const { id } = req.params;
    let allBags
    let total = 0
    let filteredBags = []
    let formattedInventories = []
    const fridge = await Fridge.findById(id);
    if (fridge.fridgeType === "Unpasteurized") {
        const inventories = await Inventory.find({ fridge: id })
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
                            select: "volume expressDate status donor",
                            populate: {
                                path: "donor",
                                select: "user",
                                populate: {
                                    path: "user",
                                    select: "name email phone"
                                }
                            }
                        },
                        {
                            path: "attendance.additionalBags",
                            select: "volume expressDate status donor",
                            populate: {
                                path: "donor",
                                select: "user",
                                populate: {
                                    path: "user",
                                    select: "name email phone"
                                }
                            }
                        }
                    ]
                },
                {
                    path: 'privDetails',
                    populate: [
                        {
                            path: 'donorDetails.donorId',
                            populate: { path: 'user', select: 'name phone' }
                        },
                        {
                            path: 'donorDetails.bags',
                            select: "volume expressDate status donor",
                            populate: {
                                path: "donor",
                                select: "user",
                                populate: {
                                    path: "user",
                                    select: "name email phone"

                                }
                            }
                        }
                    ]
                }]
            })
            .sort({ 'unpasteurizedDetails.expressDateStart': 1 })

        formattedInventories = inventories.map(inventory => {
            const attendance = inventory?.unpasteurizedDetails?.collectionId?.pubDetails?.attendance || [];
            const donorDetails = inventory?.unpasteurizedDetails?.collectionId?.privDetails?.donorDetails || [];

            // Calculate total bags from pubDetails.attendance
            const attendanceBagsCount = attendance.reduce((sum, att) =>
                sum + (att.bags?.length || 0) + (att.additionalBags?.length || 0), 0
            );

            // Calculate total volume from pubDetails.attendance
            const attendanceVolume = attendance.reduce((sum, att) =>
                sum + (att.bags?.reduce((acc, bag) => acc + (bag.volume || 0), 0) || 0) +
                (att.additionalBags?.reduce((acc, bag) => acc + (bag.volume || 0), 0) || 0), 0
            );

            // Ensure donorBags is an array, even if donorDetails is missing or empty
            const donorBags = donorDetails?.bags || [];

            const donorBagsCount = donorBags.length;

            // Calculate total volume from privDetails.donorDetails.bags
            const donorVolume = donorBags.reduce((sum, bag) => sum + (bag.volume || 0), 0);



            return {
                ...inventory.toObject(),
                totalBags: attendanceBagsCount + donorBagsCount,  // Sum of all bags
                totalVolume: attendanceVolume + donorVolume       // Sum of all volumes
            };
        });

        if (inventories) {
            allBags = inventories.flatMap(inv => {
                if (inv?.unpasteurizedDetails?.collectionId?.pubDetails) {
                    return inv.unpasteurizedDetails.collectionId.pubDetails.attendance?.flatMap(att => [
                        ...(att.bags || []),
                        ...(att.additionalBags || [])
                    ]) || [];
                } else if (inv?.unpasteurizedDetails?.collectionId?.privDetails) {
                    return inv.unpasteurizedDetails.collectionId.privDetails.donorDetails?.bags || [];
                }

                return []; // <- Always return an array
            });
            filteredBags = allBags
                .filter(bag => bag.status !== "Pasteurized") // Filter out "Pasteurized" bags
                .sort((a, b) => new Date(a.expressDate) - new Date(b.expressDate)); // Sort by expressDate

        }

    }
    else if (fridge.fridgeType === "Pasteurized") {
        const inventories = await Inventory.find({ fridge: id })
            .populate({
                path: "pasteurizedDetails.donors",
                populate: {
                    path: "user",
                    select: "name"
                }
            })
            .sort({ 'pasteurizedDetails.pasteurizationDate': 1 })
        formattedInventories = inventories
    }


    res.status(200).json({
        success: true,
        fridge,
        inventories: formattedInventories,
        allBags: filteredBags || [],
        // total
    })
})