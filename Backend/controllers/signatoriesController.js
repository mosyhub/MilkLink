const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const Signatories = require('../models/signatories')


exports.createSignatories = catchAsyncErrors(async (req, res, next) => {
    const sign = await Signatories.create(req.body);
    res.status(201).json({
        success: true,
        sign
    })
})

exports.updateSignatories = catchAsyncErrors(async (req, res, next) => {
    const {newSignatories} = req.body;
    const sign = await Signatories.findByIdAndUpdate(
        req.params.id,
        newSignatories,
        {
            new: true,
            runValidators: true,
            useFindAndModify: false,
        }
    );
    res.status(200).json({
        success: true,
        sign
    })
})

exports.getSignatories = catchAsyncErrors(async (req, res, next) => {
    const signs = await Signatories.find();
    res.status(200).json({
        success: true,
        signs
    })
})