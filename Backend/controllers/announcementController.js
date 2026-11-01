
const Announcement = require('../models/announcement');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const cloudinary = require('cloudinary');

// Upload images to Cloudinary
const uploadImages = async (images = []) => {
    if (!images) return [];

    if (typeof images === 'string') {
        images = [images];
    }

    if (!Array.isArray(images)) {
        throw new Error('Invalid images format');
    }

    const uploadedImages = [];

    for (const image of images) {
        if (typeof image === 'object' && image.url) {
            uploadedImages.push(image);
            continue;
        }

        const result = await cloudinary.v2.uploader.upload(image, {
            folder: 'articles',
        });

        uploadedImages.push({
            public_id: result.public_id,
            url: result.secure_url,
        });
    }

    return uploadedImages;
};

// Delete images from Cloudinary
const deleteCloudinaryImages = async (images = []) => {
    for (const image of images) {
        if (image.public_id) {
            try {
                await cloudinary.v2.uploader.destroy(image.public_id);
            } catch (error) {
                console.error(
                    'Cloudinary deletion error:',
                    error.message
                );
            }
        }
    }
};

// Build search filter
const buildSearchFilter = (search) => {
    if (!search) return {};

    return {
        title: {
            $regex: search,
            $options: 'i',
        },
    };
};

// Get all active announcements
exports.allAnnouncements = catchAsyncErrors(async (req, res) => {
    const { search } = req.query;

    const query = buildSearchFilter(search);

    const [articles, count] = await Promise.all([
        Announcement.findActive(query)
            .sort({ createdAt: -1 }),

        Announcement.countDocuments({
            ...query,
            isDeleted: false,
        }),
    ]);

    res.status(200).json({
        success: true,
        count,
        articles,
    });
});

exports.createHTMLAnnouncement = catchAsyncErrors(async (req, res) => {
    const { title, description } = req.body;

    const images = await uploadImages(req.body.images);

    const article = await Announcement.create({
        ...req.body,
        title,
        description,
        images,
    });

    res.status(201).json({
        success: true,
        article,
    });
});

// Create announcement
exports.createAnnouncement = catchAsyncErrors(async (req, res) => {
    const images = await uploadImages(req.body.images);

    const article = await Announcement.create({
        ...req.body,
        images,
    });

    res.status(201).json({
        success: true,
        articles: article,
    });
});

// Get announcement details
exports.getAnnouncementDetails = catchAsyncErrors(async (req, res, next) => {
    const article = await Announcement.findById(req.params.id);

    if (!article) {
        return next(
            new ErrorHandler(
                `Announcement not found with ID: ${req.params.id}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        article,
    });
});

exports.updateHTMLAnnouncement = catchAsyncErrors(async (req, res, next) => {
    let article = await Announcement.findById(req.params.id);

    if (!article) {
        return next(new ErrorHandler('Announcement not found', 404));
    }

    const updateData = {
        ...req.body,
    };

    if (updateData.title === '') {
        updateData.title = article.title;
    }

    if (updateData.description === '') {
        updateData.description = article.description;
    }

    delete updateData.isDeleted;
    delete updateData.deletedAt;

    article = await Announcement.findByIdAndUpdate(
        req.params.id,
        { $set: updateData },
        {
            new: true,
            runValidators: true,
        }
    );

    res.status(200).json({
        success: true,
        article,
    });
});

// Update announcement
exports.updateAnnouncement = catchAsyncErrors(async (req, res, next) => {
    let article = await Announcement.findById(req.params.id);

    if (!article) {
        return next(new ErrorHandler('Announcement not found', 404));
    }

    const updateData = {
        ...req.body,
    };

    let newImages = null;

    // Only replace images when images are supplied
    if (req.body.images !== undefined) {
        newImages = await uploadImages(req.body.images);
        updateData.images = newImages;
    }

    if (updateData.description === '') {
        updateData.description = article.description;
    }

    if (updateData.title === '') {
        updateData.title = article.title;
    }

    // Prevent modifying soft-delete fields through this endpoint
    delete updateData.isDeleted;
    delete updateData.deletedAt;

    article = await Announcement.findByIdAndUpdate(
        req.params.id,
        { $set: updateData },
        {
            new: true,
            runValidators: true,
        }
    );

    // Delete old images only after successful database update
    if (newImages !== null) {
        await deleteCloudinaryImages(
            article.images.filter(
                oldImage => !newImages.some(
                    newImage => newImage.public_id === oldImage.public_id
                )
            )
        );
    }

    res.status(200).json({
        success: true,
        article,
    });
});

// Permanently delete
exports.deleteAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const article = await Announcement.findByIdAndDelete(req.params.id);

    if (!article) {
        return next(
            new ErrorHandler(
                `Announcement not found with ID: ${req.params.id}`,
                404
            )
        );
    }

    await deleteCloudinaryImages(article.images);

    res.status(200).json({
        success: true,
        message: 'Announcement permanently deleted',
    });
});

// Soft-delete 
exports.softDeleteAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();

    const article = await Announcement.softDeleteById(cleanId);

    if (!article) {
        return next(
            new ErrorHandler(
                `Announcement not found with ID: ${cleanId}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        message: 'Announcement successfully archived',
        article,
    });
});

// Restore
exports.restoreAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();

    const article = await Announcement.restoreById(cleanId);

    if (!article) {
        return next(
            new ErrorHandler(
                `Deleted article not found with ID: ${cleanId}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        message: 'Announcement successfully restored',
        article,
    });
});

//Archived
exports.archivedAnnouncements = catchAsyncErrors(async (req, res) => {
    const { search } = req.query;

    const query = buildSearchFilter(search);

    const articles = await Announcement.findOnlyDeleted(query)
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: articles.length,
        articles,
    });
});
