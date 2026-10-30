import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'

const VITE_APP_URL = import.meta.env.VITE_APP_URL;
export const getMilkPerMonth = createAsyncThunk(
    'milkPerMonth/getMilkPerMonth',
    async ({ year = "" } = {}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            console.log("Fetching milk per month...")
            let urlString = `${VITE_APP_URL}/api/v1/milkPerMonth`
            if (year !== "") {
                urlString += `?year=${year}`
            }
            console.log("urlString: ", urlString)
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getDonorsPerMonth = createAsyncThunk(
    'donorsPerMonth/getDonorsPerMonth',
    async ({ year = "" } = {}, thunkAPI) => {


        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            let urlString = `${VITE_APP_URL}/api/v1/donorsPerMonth`
            if (year !== "") {
                urlString += `?year=${year}`
            }
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getDispensedMilkPerMonth = createAsyncThunk(
    'donorsPerMonth/getDispensedMilkPerMonth',
    async ({ year = "" } = {}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            let urlString = `${VITE_APP_URL}/api/v1/dispensePerMonth`
            if (year !== "") {
                urlString += `?year=${year}`
            }
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getPatientsPerMonth = createAsyncThunk(
    'donorsPerMonth/getPatientsPerMonth',
    async ({ year = "" } = {}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            let urlString = `${VITE_APP_URL}/api/v1/patientsPerMonth`;
            if (year !== "") {
                urlString += `?year=${year}`
            }
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getRequestsPerMonth = createAsyncThunk(
    'donorsPerMonth/getRequestsPerMonth',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/requestsPerMonth`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getAvailableMilk = createAsyncThunk(
    'donorsPerMonth/getAvailableMilk',
    async ({ year = "" } = {}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            let urlString = `${VITE_APP_URL}/api/v1/availableMilk`
            if (year !== "") {
                urlString += `?year=${year}`
            }
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getExpiringMilk = createAsyncThunk(
    'donorsPerMonth/getExpiringMilk',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/expiringMilk`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getVolumePerLocation = createAsyncThunk(
    'donorsPerMonth/getVolumePerLocation',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/donationLocation`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getDonorLocation = createAsyncThunk(
    'donorsPerMonth/getDonorLocation',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/donorLocation`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getPatientHospital = createAsyncThunk(
    'donorsPerMonth/getPatientHospital',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/patientHospital`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getPasteurizedMilkPerMonth = createAsyncThunk(
    'donorsPerMonth/getPasteurizedMilkPerMonth',
    async ({ year = "" } = {}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            let urlString = `${VITE_APP_URL}/api/v1/pasteurizedMilkPerMonth`
            if (year !== "") {
                urlString += `?year=${year}`
            }
            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getDonorAgeDemographic = createAsyncThunk(
    'donorsPerMonth/getDonorAgeDemographic',
    async (thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/donorAge`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)