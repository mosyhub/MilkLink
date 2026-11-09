const express = require('express');
const router = express.Router();
const upload = require('../utils/multer');

const { isAuthenticatedUser, authorizeRoles, optionalAuth } = require('../middlewares/auth');
const {
    allArticles,
    createArticle,
    updateArticle,
    deleteArticle,
    getArticleDetails,
    softDeleteArticle,
    restoreArticle,
    archivedArticles
} = require('../controllers/articleController');

const adminOnly = [isAuthenticatedUser, authorizeRoles('SuperAdmin', 'Admin')];

router.route('/articles')
    .get(optionalAuth, allArticles)
    .post(...adminOnly, upload.single('file'), createArticle);

router.route('/article/:id')
    .get(optionalAuth, getArticleDetails)
    .put(...adminOnly, updateArticle)
    .delete(...adminOnly, deleteArticle);

router.route('/article/archive/:id')
    .put(...adminOnly, softDeleteArticle);

router.route('/article/restore/:id')
    .put(...adminOnly, restoreArticle);

router.route('/articles/archived')
    .get(...adminOnly, archivedArticles);

module.exports = router;
