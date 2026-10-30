// api/setupInterceptor.js
import store from '../redux/store';
import api from './axiosInstance';
import { logoutUser } from '../redux/actions/userActions';

let isRefreshing = false;

export const setupAxiosInterceptors = () => {
    api.interceptors.response.use(
        response => response,
        async (error) => {
            const originalRequest = error.config;

            // Only intercept 401 errors once per request
            if (error.response?.status === 401 && !originalRequest._retry) {
                originalRequest._retry = true;

                if (!isRefreshing) {
                    isRefreshing = true;
                    try {
                        // Try refreshing the token
                        await api.post('/api/v1/refresh-token', {}, { withCredentials: true });
                        isRefreshing = false;

                        // Retry the original request with new token
                        return api(originalRequest);
                    } catch (refreshError) {
                        isRefreshing = false;
                        store.dispatch(logoutUser('session expired'));
                        return Promise.reject(refreshError);
                    }
                }
            }

            return Promise.reject(error);
        }
    );
};
