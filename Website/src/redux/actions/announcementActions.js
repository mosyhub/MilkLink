import { createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';
const VITE_APP_URL = import.meta.env.VITE_APP_URL;
import api from '../../api/axiosInstance';
export const getAnnouncement = createAsyncThunk(
    'announcement/getAnnouncement',
    async (query, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            let urlString = ''
            if (query) {
                urlString = `${VITE_APP_URL}/api/v1/announcements?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/announcements`
            }
            const response = await axios.get(urlString,config);
            console.log("Response", response.data)
            console.log("URL: ", urlString)
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const addAnnouncements = createAsyncThunk(
    'announcement/addAnnouncements',
    async (req, thunkAPI) => {

        
        const config = {
            headers: {

                
            },
            withCredentials: true
        }
        try {
            console.log("sending request");

            const response = await api.post(`${VITE_APP_URL}/api/v1/announcements`, req, config);
            console.log("response: ", response);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateAnnouncements = createAsyncThunk(
    'announcement/updateAnnouncements',
    async (req, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/announcement/${req.id}`, req, config);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const deleteAnnouncement = createAsyncThunk(
    'announcement/deleteAnnouncement',
    async (id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/announcement/${id}`, config);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getAnnouncementDetails = createAsyncThunk(
    'announcement/getAnnouncementDetails',
    async (id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/announcement/${id}`, config);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const addHTMLAnnouncements = createAsyncThunk(
    'announcement/addHTMLAnnouncements',
    async (req, thunkAPI) => {

        
        const config = {
            headers: {

                
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/html-announcement`, req, config);
            console.log("response: ", response.data);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const updateHTMLAnnouncement = createAsyncThunk(
    'announcement/updateHTMLAnnouncement',
    async (req, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/html-announcement/${req.id}`, req, config);
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const softDeleteAnnouncement = createAsyncThunk(
    'announcement/softDeleteAnnouncement',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/announcement/archive/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
export const restoreAnnouncement = createAsyncThunk(
    'announcement/restoreAnnouncement',
    async(id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/announcement/restore/${id}`, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getArchivedAnnouncements = createAsyncThunk(
    'announcement/getArchivedAnnouncements',
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
                urlString = `${VITE_APP_URL}/api/v1/announcements/archived?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/announcements/archived`
            }
            const response = await api.get(urlString, config);
            return response.data;
        }catch (error){
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)