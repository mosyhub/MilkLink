const Article = require('../models/articles');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const cloudinary = require('cloudinary');

// Simple sanitizer
const sanitize = (text) => {
    if (typeof text !== 'string') return text;
    return text.replace(/<[^>]*>?/gm, '').trim();
};

// Upload images to Cloudinary
const uploadImages = async (images = [], folder = 'articles') => {
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
            folder: folder,
        });

        uploadedImages.push({
            public_id: result.public_id,
            url: result.secure_url,
        });
    }

    return uploadedImages;
};

// Delete Cloudinary images
const deleteCloudinaryImages = async (images = []) => {
    if (!Array.isArray(images)) return;

    await Promise.allSettled(
        images.map(async (image) => {
            if (!image?.public_id) return;
            try {
                await cloudinary.v2.uploader.destroy(image.public_id);
            } catch (err) {
                console.error('Cloudinary deletion error:', err.message);
            }
        })
    );
};

// Get all articles
// Rules:
// - Non-Admin users see ONLY active, non-archived items.
// - Admin sees active, archived, or all depending on query status.
exports.allArticles = catchAsyncErrors(async (req, res) => {
    const { search, status = 'Active', page = 1, limit = 20 } = req.query;
    const isAdmin = req.user && ['Admin', 'SuperAdmin'].includes(req.user.role);

    const query = {};

    if (!isAdmin) {
        query.isDeleted = false;
    } else {
        if (status === 'Archived') {
            query.isDeleted = true;
        } else if (status === 'Active') {
            query.isDeleted = false;
        } else {
            query.includeDeleted = true;
        }
    }

    if (search && search.trim() !== '') {
        query.$or = [
            { title: { $regex: search.trim(), $options: 'i' } },
            { description: { $regex: search.trim(), $options: 'i' } }
        ];
    }

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;
    const skip = (pageNum - 1) * limitNum;

    const findQuery = query.includeDeleted
        ? Article.find(query).setOptions({ skipDeletedFilter: true })
        : (query.isDeleted ? Article.findOnlyDeleted(query) : Article.findActive(query));

    const [articles, total] = await Promise.all([
        findQuery
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum),
        Article.countDocuments(query).setOptions({ skipDeletedFilter: true })
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

// Create article (Admin only)
exports.createArticle = catchAsyncErrors(async (req, res, next) => {
    const { title, description, content } = req.body;

    if (!title || !title.trim()) {
        return next(new ErrorHandler('Article title is required', 400));
    }
    if (!description || !description.trim()) {
        return next(new ErrorHandler('Article description is required', 400));
    }
    if (!content || !content.trim()) {
        return next(new ErrorHandler('Article content is required', 400));
    }

    const images = await uploadImages(req.body.images, 'articles');

    const article = await Article.create({
        title: sanitize(title),
        description: sanitize(description),
        content: content.trim(), // Preserve multiline/paragraphs
        images,
    });

    res.status(201).json({
        success: true,
        article,
        articles: article,
    });
});

// Get article details
exports.getArticleDetails = catchAsyncErrors(async (req, res, next) => {
    const isAdmin = req.user && ['Admin', 'SuperAdmin'].includes(req.user.role);

    const article = await Article.findById(req.params.id)
        .setOptions({ skipDeletedFilter: isAdmin });

    if (!article) {
        return next(new ErrorHandler(`Article not found with ID: ${req.params.id}`, 404));
    }

    if (!isAdmin && article.isDeleted) {
        return next(new ErrorHandler('You do not have access to this article', 403));
    }

    res.status(200).json({
        success: true,
        article,
    });
});

// Update article (Admin only)
exports.updateArticle = catchAsyncErrors(async (req, res, next) => {
    let article = await Article.findById(req.params.id).setOptions({ skipDeletedFilter: true });

    if (!article) {
        return next(new ErrorHandler('Article not found', 404));
    }

    const { title, description, content } = req.body;
    const updateData = {};

    if (title !== undefined) updateData.title = sanitize(title);
    if (description !== undefined) updateData.description = sanitize(description);
    if (content !== undefined) updateData.content = content.trim();

    let newImages = null;
    if (req.body.images !== undefined) {
        newImages = await uploadImages(req.body.images, 'articles');
        updateData.images = newImages;
    }

    delete updateData.isDeleted;
    delete updateData.deletedAt;

    const oldImages = [...(article.images || [])];

    article = await Article.findByIdAndUpdate(
        req.params.id,
        { $set: updateData },
        { new: true, runValidators: true }
    );

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

// Permanently delete article (Admin only, only from archived)
exports.deleteArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findOne({ _id: req.params.id, isDeleted: true }).setOptions({ skipDeletedFilter: true });

    if (!article) {
        return next(new ErrorHandler('Permanent delete is only permitted on archived articles', 400));
    }

    await deleteCloudinaryImages(article.images);
    await Article.findByIdAndDelete(req.params.id);

    res.status(200).json({
        success: true,
        message: 'Article permanently deleted',
    });
});

// Soft delete / Archive
exports.softDeleteArticle = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const article = await Article.softDeleteById(cleanId);

    if (!article) {
        return next(new ErrorHandler(`Article not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Article successfully archived',
        article,
    });
});

// Restore from Archive
exports.restoreArticle = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();
    const article = await Article.restoreById(cleanId);

    if (!article) {
        return next(new ErrorHandler(`Deleted article not found with ID: ${cleanId}`, 404));
    }

    res.status(200).json({
        success: true,
        message: 'Article successfully restored',
        article,
    });
});

// Archived articles
exports.archivedArticles = catchAsyncErrors(async (req, res) => {
    const { search } = req.query;
    const query = {};

    if (search && search.trim() !== '') {
        query.$or = [
            { title: { $regex: search.trim(), $options: 'i' } },
            { description: { $regex: search.trim(), $options: 'i' } }
        ];
    }

    const articles = await Article.findOnlyDeleted(query)
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: articles.length,
        articles,
    });
});
