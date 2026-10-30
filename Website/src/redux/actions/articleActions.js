import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

export const getArticles = createAsyncThunk(
    'article/getArticles',
    async(query, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            let urlString = ''
            if (query){
                urlString = `${VITE_APP_URL}/api/v1/articles?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/articles`
            }
            const response = await api.get(urlString, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getArchivedArticles = createAsyncThunk(
    'article/getArchivedArticles',
    async(query, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            let urlString = ''
            if (query){
                urlString = `${VITE_APP_URL}/api/v1/articles/archived?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/articles/archived`
            }
            const response = await api.get(urlString, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const addArticles = createAsyncThunk(
    'article/addArticles',
    async(req, thunkAPI) => {
        
        
        const config = {
            headers: {
                
                
            },
            withCredentials: true
        }
        try {
            console.log("sending request");
            console.log(`${VITE_APP_URL}/api/v1/articles`)
            const response = await api.post(`${VITE_APP_URL}/api/v1/articles`, req, config);
            console.log("response: ", response);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const addHTMLArticles = createAsyncThunk(
    'article/addHTMLArticles',
    async(req, thunkAPI) => {
        
        
        const config = {
            headers: {
                
                
            },
            withCredentials: true
        }
        try {
           
            const response = await api.post(`${VITE_APP_URL}/api/v1/html-article`, req, config);
            console.log("response: ", response.data);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateHTMLArticle = createAsyncThunk(
    'article/updateHTMLArticle',
    async(req, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/html-article/${req.id}`, req, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateArticle = createAsyncThunk(
    'article/updateArticle',
    async(req, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/articles/${req.id}`, req, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const deleteArticle = createAsyncThunk(
    'article/deleteArticle',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/article/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
export const softDeleteArticle = createAsyncThunk(
    'article/softDeleteArticle',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/article/archive/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
export const restoreArticle = createAsyncThunk(
    'article/restoreArticle',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/article/restore/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getArticleDetails = createAsyncThunk(
    'article/getArticleDetails',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/article/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)