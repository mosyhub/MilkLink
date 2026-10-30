import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance';

// Get notifications with Token
export const notifChecker = createAsyncThunk(
    'notifications/notifChecker',
    async (data, thunkAPI) => {

        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`/api/v1/notifications/check`, data, config);

            return response.data;

        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getUserNotifications = createAsyncThunk(
    'notifications/getUserNotifications',
    async (_, thunkAPI) => {

        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`/api/v1/notifications`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Send Notification
export const sendNotifications = createAsyncThunk(
    'notifications/sendNotifications',
    async (data, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`/api/v1/notifications/send`, data, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Send push notification
export const sendSingleUserNotif = createAsyncThunk('notifications/sendSingleUserNotif', async (data, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

    try {

        const response = await api.post(`/api/v1/notifications/send/single`, data, config)
            
        return response.data;
    } catch (error) {
        
        return thunkAPI.rejectWithValue(error.response?.data?.errMessage || 'Failed to send notification');
    }
});

// Seen Notification
export const markAsSeen = createAsyncThunk(
    'notifications/markAsSeen',
    async (id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.put(`/api/v1/notifications/${id}`, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Delete Notification
export const deleteNotif = createAsyncThunk(
    'notifications/deleteNotif',
    async (id, thunkAPI) => {
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.put(`/api/v1/notifications/${id}`, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)