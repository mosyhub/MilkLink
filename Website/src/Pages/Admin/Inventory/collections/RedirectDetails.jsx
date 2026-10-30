import { useNavigate, useLocation, useParams } from "react-router-dom";
import React, { useEffect } from "react";

const RedirectDetails = () => {
    const navigate = useNavigate();
    const { id } = useParams();
    const location = useLocation();
    const type = location.state?.type
    const collectionId = location.state?.collectionId
    const status = location.state?.status
    useEffect(() => {
        if (type) {
            if (type === "Public") {
                navigate(`/dashboard/events/attendance/${id}`, {state: {from: "RedirectDetails", status: status, collectionId: collectionId}});
            } else if (type === "Private") {
                navigate(`/dashboard/schedules/${id}`, {state: {from: "RedirectDetails", collectionId: collectionId, status: status}}); // Fallback if no previous page is found
            }
            console.log("Type: ", type)
        }
        else {
            console.log("none")
        }

    }, [navigate, type, id]);

    return <p>Redirecting...</p>;
};

export default RedirectDetails;