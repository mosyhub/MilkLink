const Announcement = require('../models/announcement');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const cloudinary = require('cloudinary');

// Simple sanitizer to strip script/html tags from text fields
const sanitize = (text) => {
    if (typeof text !== 'string') return text;
    return text.replace(/<[^>]*>?/gm, '').trim();
};

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
            folder: 'announcements',
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
    if (!Array.isArray(images)) return;
    for (const image of images) {
        if (image.public_id) {
            try {
                await cloudinary.v2.uploader.destroy(image.public_id);
            } catch (error) {
                console.error('Cloudinary deletion error:', error.message);
            }
        }
    }
};

// Get all announcements
// Rules:
// - Non-Admin users see ONLY active, non-archived items.
// - Admin sees active, archived, or all depending on query status.
exports.allAnnouncements = catchAsyncErrors(async (req, res) => {
    const { search, tag, status = 'Active', page = 1, limit = 20 } = req.query;
    const isAdmin = req.user && ['Admin', 'SuperAdmin'].includes(req.user.role);

    const query = {};

    if (!isAdmin) {
        // Non-admins only see active, non-deleted announcements
        query.isDeleted = false;
        query.isActive = true;
    } else {
        if (status === 'Archived') {
            query.isDeleted = true;
        } else if (status === 'Active') {
            query.isDeleted = false;
        } else {
            // 'All' - includes active and archived
            query.includeDeleted = true;
        }
    }

    if (search && search.trim() !== '') {
        query.title = { $regex: search.trim(), $options: 'i' };
    }

    if (tag && tag.trim() !== '') {
        query.tags = tag.trim();
    }

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;
    const skip = (pageNum - 1) * limitNum;

    const findQuery = query.includeDeleted
        ? Announcement.find(query).setOptions({ skipDeletedFilter: true })
        : (query.isDeleted ? Announcement.findOnlyDeleted(query) : Announcement.findActive(query));

    const [articles, total] = await Promise.all([
        findQuery
            .populate('author', 'name username email avatar')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum),
        Announcement.countDocuments(query).setOptions({ skipDeletedFilter: true })
    ]);

    res.status(200).json({
        success: true,
        count: total,
        total,
        page: pageNum,
        pages: Math.ceil(total / limitNum) || 1,
        articles,
    });
});

// Create announcement (Admin only)
exports.createAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const { title, description, tags, isActive } = req.body;

    if (!title || !title.trim()) {
        return next(new ErrorHandler('Announcement title is required', 400));
    }
    if (!description || !description.trim()) {
        return next(new ErrorHandler('Announcement description is required', 400));
    }

    const images = await uploadImages(req.body.images);

    let parsedTags = [];
    if (Array.isArray(tags)) {
        parsedTags = tags.map(t => sanitize(t)).filter(Boolean);
    } else if (typeof tags === 'string') {
        parsedTags = tags.split(',').map(t => sanitize(t)).filter(Boolean);
    }

    const announcement = await Announcement.create({
        title: sanitize(title),
        description: sanitize(description),
        images,
        tags: parsedTags,
        isActive: isActive !== undefined ? (isActive === true || isActive === 'true') : true,
        author: req.user._id, // Set author strictly from authenticated user
    });

    await announcement.populate('author', 'name username email avatar');

    res.status(201).json({
        success: true,
        article: announcement,
        articles: announcement,
    });
});

// Get announcement details
exports.getAnnouncementDetails = catchAsyncErrors(async (req, res, next) => {
    const isAdmin = req.user && ['Admin', 'SuperAdmin'].includes(req.user.role);

    const article = await Announcement.findById(req.params.id)
        .setOptions({ skipDeletedFilter: isAdmin })
        .populate('author', 'name username email avatar');

    if (!article) {
        return next(new ErrorHandler(`Announcement not found with ID: ${req.params.id}`, 404));
    }

    if (!isAdmin && (article.isDeleted || !article.isActive)) {
        return next(new ErrorHandler('You do not have access to this announcement', 403));
    }

    res.status(200).json({
        success: true,
        article,
    });
});

// Update announcement (Admin only)
exports.updateAnnouncement = catchAsyncErrors(async (req, res, next) => {
    let article = await Announcement.findById(req.params.id).setOptions({ skipDeletedFilter: true });

    if (!article) {
        return next(new ErrorHandler('Announcement not found', 404));
    }

    const { title, description, tags, isActive } = req.body;
    const updateData = {};

    if (title !== undefined) updateData.title = sanitize(title);
    if (description !== undefined) updateData.description = sanitize(description);
    if (isActive !== undefined) updateData.isActive = (isActive === true || isActive === 'true');

    if (tags !== undefined) {
        if (Array.isArray(tags)) {
            updateData.tags = tags.map(t => sanitize(t)).filter(Boolean);
        } else if (typeof tags === 'string') {
            updateData.tags = tags.split(',').map(t => sanitize(t)).filter(Boolean);
        }
    }

    let newImages = null;
    if (req.body.images !== undefined) {
        newImages = await uploadImages(req.body.images);
        updateData.images = newImages;
    }

    // Never allow author or soft-delete fields to be changed via update
    delete updateData.author;
    delete updateData.isDeleted;
    delete updateData.deletedAt;

    const oldImages = [...(article.images || [])];

    article = await Announcement.findByIdAndUpdate(
        req.params.id,
        { $set: updateData },
        { new: true, runValidators: true }
    ).populate('author', 'name username email avatar');

    // Delete old images that are no longer part of new images
    if (newImages !== null) {
        const removed = oldImages.filter(
            oldImg => !newImages.some(newImg => newImg.public_id === oldImg.public_id)
        );
        await deleteCloudinaryImages(removed);
    }

    res.status(200).json({
        success: true,
        article,
    });
});

// Permanently delete announcement (Admin only, only from archived)
exports.deleteAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const article = await Announcement.findOne({ _id: req.params.id, isDeleted: true }).setOptions({ skipDeletedFilter: true });

    if (!article) {
        return next(new ErrorHandler('Permanent delete is only permitted on archived announcements', 400));
    }

    await deleteCloudinaryImages(article.images);
    await Announcement.findByIdAndDelete(req.params.id);

    res.status(200).json({
        success: true,
        message: 'Announcement permanently deleted',
    });
});

// Soft-delete / Archive
exports.softDeleteAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const article = await Announcement.softDeleteById(cleanId);

    if (!article) {
        return next(new ErrorHandler(`Announcement not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Announcement successfully archived',
        article,
    });
});

// Restore from Archive
exports.restoreAnnouncement = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const article = await Announcement.restoreById(cleanId);

    if (!article) {
        return next(new ErrorHandler(`Deleted announcement not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Announcement successfully restored',
        article,
    });
});

// Archived announcements
exports.archivedAnnouncements = catchAsyncErrors(async (req, res) => {
    const { search, tag } = req.query;
    const query = {};

    if (search && search.trim() !== '') {
        query.title = { $regex: search.trim(), $options: 'i' };
    }
    if (tag && tag.trim() !== '') {
        query.tags = tag.trim();
    }

    const articles = await Announcement.findOnlyDeleted(query)
        .populate('author', 'name username email avatar')
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: articles.length,
        articles,
    });
});
