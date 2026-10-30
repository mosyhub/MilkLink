import { createSlice } from '@reduxjs/toolkit';
import { getArticles, addArticles, addHTMLArticles,updateHTMLArticle, updateArticle, getArticleDetails, deleteArticle, restoreArticle, softDeleteArticle, getArchivedArticles } from '../actions/articleActions';

export const articleSlice = createSlice({
    name: 'article',
    initialState: {
        articles: [],
        success: false,
        loading: false,
        error: null,
        articleDetails: {},
        isUpdated: false,
        isDeleted: false,
    },
    reducers: {
        resetUpdate: (state) => {
            state.isUpdated = false;
        },
        resetDelete: (state) => {
            state.isDeleted = false;
        },
        resetSuccess: (state) => {
            state.success = false;
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(getArticles.pending, (state) => {
                state.loading = true;
            })
            .addCase(getArticles.fulfilled, (state, action) => {
                state.loading = false;
                state.articles = action.payload.articles;
            })
            .addCase(getArticles.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getArchivedArticles.pending, (state) => {
                state.loading = true;
            })
            .addCase(getArchivedArticles.fulfilled, (state, action) => {
                state.loading = false;
                state.articles = action.payload.articles;
            })
            .addCase(getArchivedArticles.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(addArticles.pending, (state) => {
                state.loading = true;
            })
            .addCase(addArticles.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(addArticles.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(addHTMLArticles.pending, (state) => {
                state.loading = true;
            })
            .addCase(addHTMLArticles.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(addHTMLArticles.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateArticle.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateArticle.fulfilled, (state, action) => {
                state.loading = false;
                state.isUpdated = action.payload.success;
            })
            .addCase(updateArticle.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateHTMLArticle.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateHTMLArticle.fulfilled, (state, action) => {
                state.loading = false;
                state.isUpdated = action.payload.success;
            })
            .addCase(updateHTMLArticle.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getArticleDetails.pending, (state) => {
                state.loading = true;
            })
            .addCase(getArticleDetails.fulfilled, (state, action) => {
                state.loading = false;
                state.articleDetails = action.payload.article;
            })
            .addCase(getArticleDetails.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(deleteArticle.pending, (state) => {
                state.loading = true;
            })
            .addCase(deleteArticle.fulfilled, (state, action) => {
                state.loading = false;
                state.isDeleted = action.payload.success;
            })
            .addCase(deleteArticle.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(softDeleteArticle.pending, (state) => {
                state.loading = true;
            })
            .addCase(softDeleteArticle.fulfilled, (state, action) => {
                state.loading = false;
                state.isDeleted = action.payload.success;
            })
            .addCase(softDeleteArticle.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(restoreArticle.pending, (state) => {
                state.loading = true;
            })
            .addCase(restoreArticle.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(restoreArticle.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
    }
})
export const { resetUpdate, resetDelete, resetSuccess } = articleSlice.actions;
export default articleSlice.reducer;