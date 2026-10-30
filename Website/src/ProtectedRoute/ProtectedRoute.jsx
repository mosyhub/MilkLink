import React, { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { getUser } from '../utils/helper';
import PropTypes from 'prop-types';
const ProtectedRoute = ({ children, isAuthorized = false, isAdmin = false, isStaff = false }) => {
    const [loading] = useState(getUser() === false)
    const [user] = useState(getUser())

    if (!loading) {
        if (!user) {
            return <Navigate to="/login" replace />
        }
        if (isAuthorized === true && user.role === 'User') {
            return <Navigate to="/" replace />
        }
        if (isAdmin === true && (user.role !== 'Admin' && user.role !== 'SuperAdmin')) {
            return <Navigate to="/" replace />
        }
        if (isStaff === true && user.role !== 'Staff') {
            return <Navigate to="/" replace />
        }
        return children
    }
    return 'Loading...'
};

ProtectedRoute.propTypes = {
    children: PropTypes.node.isRequired,
    isAuthorized: PropTypes.bool,
    isAdmin: PropTypes.bool,
    isStaff: PropTypes.bool,
};

export default ProtectedRoute;