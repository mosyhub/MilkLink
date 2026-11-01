const Article = require('../models/articles');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const cloudinary = require('cloudinary');

// Escape special regex characters in search input
const escapeRegex = (value) => {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

// Build search filter
const buildSearchFilter = (search) => {
    if (!search || !search.trim()) return {};

    return {
        title: {
            $regex: escapeRegex(search.trim()),
            $options: 'i',
        },
    };
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

    try {
        for (const image of images) {
            // Keep existing Cloudinary images
            if (
                typeof image === 'object' &&
                image.public_id &&
                image.url
            ) {
                uploadedImages.push(image);
                continue;
            }

            // Extract image URL or base64 data
            const imageUrl =
                typeof image === 'string'
                    ? image
                    : image?.url;

            if (!imageUrl) {
                throw new Error('Invalid image data');
            }

            const result = await cloudinary.v2.uploader.upload(
                imageUrl,
                { folder }
            );

            uploadedImages.push({
                public_id: result.public_id,
                url: result.secure_url,
            });
        }

        return uploadedImages;
    } catch (error) {
        // Clean up uploads if a later upload fails
        await deleteCloudinaryImages(uploadedImages);
        throw error;
    }
};

// Delete Cloudinary images
const deleteCloudinaryImages = async (images = []) => {
    if (!Array.isArray(images)) return;

    await Promise.allSettled(
        images.map(async (image) => {
            if (!image?.public_id) return;

            await cloudinary.v2.uploader.destroy(
                image.public_id
            );
        })
    );
};

exports.allArticles = catchAsyncErrors(async (req, res) => {
    const query = buildSearchFilter(req.query.search);

    const [articles, count] = await Promise.all([
        Article.findActive(query)
            .sort({ createdAt: -1 }),

        Article.countDocuments({
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

exports.archivedArticles = catchAsyncErrors(async (req, res) => {
    const query = buildSearchFilter(req.query.search);

    const articles = await Article.findOnlyDeleted(query)
        .sort({ deletedAt: -1 });

    res.status(200).json({
        success: true,
        count: articles.length,
        articles,
    });
});

exports.createHTMLArticle = catchAsyncErrors(async (req, res) => {
    const {
        title,
        description,
        content,
    } = req.body;

    const images = await uploadImages(
        req.body.images,
        'articlesImages'
    );

    let article;

    try {
        article = await Article.create({
            title,
            description,
            content,
            images,
        });
    } catch (error) {
        await deleteCloudinaryImages(images);
        throw error;
    }

    res.status(201).json({
        success: true,
        article,
    });
});

exports.createArticle = catchAsyncErrors(async (req, res) => {
    const images = await uploadImages(
        req.body.images,
        'articles'
    );

    let article;

    try {
        article = await Article.create({
            ...req.body,
            images,
        });
    } catch (error) {
        await deleteCloudinaryImages(images);
        throw error;
    }

    res.status(201).json({
        success: true,
        articles: article,
    });
});

exports.getArticleDetails = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findById(req.params.id);

    if (!article) {
        return next(
            new ErrorHandler(
                `Article not found with ID: ${req.params.id}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        article,
    });
});

exports.updateHTMLArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findById(req.params.id);

    if (!article) {
        return next(
            new ErrorHandler('Article not found', 404)
        );
    }

    const updateData = { ...req.body };

    if (updateData.title === '') {
        updateData.title = article.title;
    }

    if (updateData.description === '') {
        updateData.description = article.description;
    }

    // Do not allow API clients to change soft-delete fields
    delete updateData.isDeleted;
    delete updateData.deletedAt;

    let newImages = null;

    if (req.body.images !== undefined) {
        const requestedImages = Array.isArray(req.body.images)
            ? req.body.images
            : [req.body.images];

        const existingImages = requestedImages.filter(
            image =>
                typeof image === 'object' &&
                image.public_id &&
                image.url
        );

        const imagesToUpload = requestedImages.filter(
            image =>
                typeof image === 'string' ||
                (typeof image === 'object' && !image.public_id && image.url)
        );

        const uploadedImages = await uploadImages(
            imagesToUpload,
            'articlesImages'
        );

        newImages = [
            ...existingImages,
            ...uploadedImages,
        ];

        updateData.images = newImages;
    }

    let updatedArticle;

    try {
        updatedArticle = await Article.findByIdAndUpdate(
            req.params.id,
            { $set: updateData },
            {
                new: true,
                runValidators: true,
            }
        );
    } catch (error) {
        if (newImages !== null) {
            const oldIds = new Set(
                article.images.map(image => image.public_id)
            );

            await deleteCloudinaryImages(
                newImages.filter(image => !oldIds.has(image.public_id))
            );
        }

        throw error;
    }

    // Delete removed images only after successful update
    if (newImages !== null) {
        const retainedIds = new Set(
            newImages.map(image => image.public_id)
        );

        const removedImages = article.images.filter(
            image => !retainedIds.has(image.public_id)
        );

        await deleteCloudinaryImages(removedImages);
    }

    res.status(200).json({
        success: true,
        article: updatedArticle,
    });
});

exports.updateArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findById(req.params.id);

    if (!article) {
        return next(
            new ErrorHandler('Article not found', 404)
        );
    }

    const updateData = { ...req.body };

    if (updateData.title === '') {
        updateData.title = article.title;
    }

    if (updateData.description === '') {
        updateData.description = article.description;
    }

    delete updateData.isDeleted;
    delete updateData.deletedAt;

    let newImages = null;

    // Only update images if the request contains an images property
    if (req.body.images !== undefined) {
        newImages = await uploadImages(
            req.body.images,
            'articles'
        );

        updateData.images = newImages;
    }

    try {
        const updatedArticle = await Article.findByIdAndUpdate(
            req.params.id,
            { $set: updateData },
            {
                new: true,
                runValidators: true,
            }
        );

        // Clean up old images after successful update
        if (newImages !== null) {
            const retainedIds = new Set(
                newImages.map(image => image.public_id)
            );

            const removedImages = article.images.filter(
                image => !retainedIds.has(image.public_id)
            );

            await deleteCloudinaryImages(removedImages);
        }

        res.status(200).json({
            success: true,
            article: updatedArticle,
        });
    } catch (error) {
        // Remove newly uploaded images if database update fails
        if (newImages !== null) {
            const oldIds = new Set(
                article.images.map(image => image.public_id)
            );

            await deleteCloudinaryImages(
                newImages.filter(image => !oldIds.has(image.public_id))
            );
        }

        throw error;
    }
});

exports.deleteArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findOneAndDelete({
        _id: req.params.id,
        isDeleted: false,
    });

    if (!article) {
        return next(
            new ErrorHandler(
                `Article not found with ID: ${req.params.id}`,
                404
            )
        );
    }

    await deleteCloudinaryImages(article.images);

    res.status(200).json({
        success: true,
        message: 'Article permanently deleted',
    });
});

exports.softDeleteArticle = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();

    const article = await Article.softDeleteById(cleanId);

    if (!article) {
        return next(
            new ErrorHandler(
                `Article not found with ID: ${cleanId}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        message: 'Article successfully archived',
        article,
    });
});

exports.restoreArticle = catchAsyncErrors(async (req, res, next) => {
    const cleanId = req.params.id.trim();

    const article = await Article.restoreById(cleanId);

    if (!article) {
        return next(
            new ErrorHandler(
                `Archived article not found with ID: ${cleanId}`,
                404
            )
        );
    }

    res.status(200).json({
        success: true,
        message: 'Article successfully restored',
        article,
    });
});
