const Article = require('../models/articles');
const ErrorHandler = require('../utils/errorHandler');
const catchAsyncErrors = require('../middlewares/catchAsyncErrors');
const cloudinary = require('cloudinary');

exports.allArticles = catchAsyncErrors(async (req, res, next) => {
    const { search } = req.query;
    let query = {};
    if (search) {
        query.$or = [
            { 'title': { $regex: search, $options: 'i' } },
        ];
    }
    const articles = await Article.find(query).sort({ createdAt: -1 });

    const count = await Article.countDocuments();

    res.status(200).json({
        success: true,
        count,
        articles
    })

})
exports.archivedArticles = catchAsyncErrors(async (req, res, next) => {
    const { search } = req.query;
    let query = {};
    if (search) {
        query.$or = [
            { 'title': { $regex: search, $options: 'i' } },
        ];
    }
    const articles = await Article.findOnlyDeleted(query).sort({ deletedAt: -1 });
    res.status(200).json({
        success: true,
        articles
    });
});
exports.createHTMLArticle = catchAsyncErrors(async (req, res, next) => {
    try {
        let { content, title, description } = req.body;
        let images = [];
        if (typeof req.body.images === "string") {
            images.push(req.body.images);
        } else {
            images = req.body.images;
        }

        let imagesLinks = [];

        for (let i = 0; i < images.length; i++) {
            const result = await cloudinary.v2.uploader.upload(images[i], {
                folder: "articlesImages",
            });
            imagesLinks.push({
                public_id: result.public_id,
                url: result.secure_url,
            });
        }

        req.body.images = imagesLinks;

        // Save article with updated content
        const article = await Article.create({
            title,
            description,
            content,
            images: req.body.images,
        });

        res.status(201).json({
            success: true,
            article,
        });
    } catch (error) {
        console.log("Error: ", error.message);
        next(error);
    }
})


exports.createArticle = catchAsyncErrors(async (req, res, next) => {
    try {
        let images = []
        if (typeof req.body.images === 'string') {
            images.push(req.body.images)
        }
        else {
            images = req.body.images
        }

        let imagesLinks = [];

        for (let i = 0; i < images.length; i++) {
            const result = await cloudinary.v2.uploader.upload(images[i], {
                folder: 'articles'
            });

            imagesLinks.push({
                public_id: result.public_id,
                url: result.secure_url
            });
        }
        req.body.images = imagesLinks;

        const articles = await Article.create(
            req.body
        );

        res.status(201).json({
            success: true,
            articles,
        });
    }
    catch (error) {
        console.log('Error: ', error.message);
        next(error);
    }
})

exports.getArticleDetails = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findById(req.params.id);
    if (!article) {
        return next(new ErrorHandler(`Article is not found with this id: ${req.params.id}`));
    }
    res.status(200).json({
        success: true,
        article
    })
})

exports.updateHTMLArticle = catchAsyncErrors(async (req, res, next) => {
    const data = req.body;
    try {
        let article = await Article.findById(req.params.id);
        if (!article) {
            return next(new ErrorHandler('Article not found', 404));
        }
        if (data.title === '') {
            data.title = article.title;
        }

        if (data.description === '') {
            data.description = article.description;
        }

        let newImages = [];
        let existingImages = [];

        if (Array.isArray(data.images)) {
            data.images.forEach((image) => {
                if (image.public_id) {
                    existingImages.push(image); // Existing image
                } else if (image.local) {
                    newImages.push(image.url); // New base64 image
                }
            });
        }

        // Remove deleted images
        for (let oldImage of article.images) {
            if (!existingImages.some((img) => img.public_id === oldImage.public_id)) {
                await cloudinary.v2.uploader.destroy(oldImage.public_id);
            }
        }

        // Upload new base64 images
        let uploadedImages = [];
        for (let imageUri of newImages) {
            if (!imageUri.startsWith("data:image")) {
                console.log("Skipping invalid image format:", imageUri);
                continue;
            }

            const result = await cloudinary.v2.uploader.upload(imageUri, {
                folder: "articlesImages",
            });

            uploadedImages.push({
                public_id: result.public_id,
                url: result.secure_url,
            });
        }

        // Merge and update
        data.images = [...existingImages, ...uploadedImages];

        const updatedArticle = await Article.findByIdAndUpdate(req.params.id, data, {
            new: true,
            runValidators: true,
            useFindAndModify: false,
        })

        res.status(200).json({
            success: true,
            article: updatedArticle
        })
    } catch (error) {
        console.log('Error: ', error.message);
        next(error);
    }
})




exports.updateArticle = catchAsyncErrors(async (req, res, next) => {
    console.log(req.body);
    try {
        let article = await Article.findById(req.params.id);
        if (!article) {
            return next(new ErrorHandler('Article not found', 404));
        }
        let images = [];
        if (Array.isArray(req.body.images)) {
            images = req.body.images.map(image => typeof image === 'object' && image.url ? image.url : image);
        }
        else if (typeof req.body.images === 'string') {
            images.push(req.body.images);
        }

        if (images.length > 0) {
            for (let i = 0; i < article.images.length; i++) {
                await cloudinary.v2.uploader.destroy(article.images[i].public_id);
            }
            let imagesLinks = [];
            for (let i = 0; i < images.length; i++) {
                const result = await cloudinary.v2.uploader.upload(images[i], {
                    folder: 'articles',
                });
                imagesLinks.push({
                    public_id: result.public_id,
                    url: result.secure_url,
                })
            }
            req.body.images = imagesLinks
        }

        if (req.body.description === '') {
            req.body.description = article.description;
        }

        if (req.body.images.length === 0) {
            article = await Article.findByIdAndUpdate(req.params.id, {
                title: req.body.title,
                description: req.body.description,
            }, {
                new: true,
                runValidators: true,
                useFindAndModify: false,
            })
        }
        else {
            article = await Article.findByIdAndUpdate(req.params.id, req.body, {
                new: true,
                runValidators: true,
                useFindAndModify: false,
            })
        }


        res.status(200).json({
            success: true,
            article
        })
    } catch (error) {
        console.log('Error: ', error.message);
        next(error);
    }
})


exports.deleteArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.findByIdAndDelete(req.params.id);

    if (!article) {
        return next(new ErrorHandler(`Article is not found with this id: ${req.params.id}`))
    }
    for (let i = 0; i < article.images.length; i++) {
        const result = await cloudinary.v2.uploader.destroy(article.images[i].public_id)
    }

    res.status(200).json({
        success: true,
        message: 'Article is deleted'
    })
})

exports.softDeleteArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.softDeleteById(req.params.id);

    if (!article) {
        return next(new ErrorHandler(`Article is not found with this id: ${req.params.id}`))
    }

    res.status(200).json({
        success: true,
        message: 'Article is soft deleted'
    })
})

exports.restoreArticle = catchAsyncErrors(async (req, res, next) => {
    const article = await Article.restoreById(req.params.id);

    if (!article) {
        return res.status(404).json({
            success: false,
            message: `Article with id ${req.params.id} not found`
        });
    }

    return res.status(200).json({
        success: true,
        message: 'Article is restored'
    });
});
