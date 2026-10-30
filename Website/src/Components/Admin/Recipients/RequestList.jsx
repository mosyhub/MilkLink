import React from 'react'
import { formatDate } from '../../../utils/helper'
import { Typography } from '@material-tailwind/react'
import PropTypes from 'prop-types'
const RequestList = ({ requests }) => {
    
    return (
        <article className="rounded-xl w-full border border-gray-70 p-4">
            <div className="flex items-center gap-4">
                <Typography color="black" variant="h2">Request History</Typography>
            </div>

            <ul className="mt-4 space-y-2">
                {requests.map((request) => (
                        <li key={request._id}>
                        <p className="block h-full rounded-lg border border-gray-500 p-4">
                            <strong className="font-medium text-lg text-black">Date: {formatDate(request.date)}</strong>
                            <p className="mt-1 text-lg font-medium text-gray-800">Requested Volume: {request.volumeRequested.volume} mL/day</p>
                            <p className="mt-1 text-lg font-medium text-gray-800">Diagnosis: {request.diagnosis}</p>
                            <p className="mt-1 text-lg font-medium text-gray-800">Reason for request: {request.reason}</p>
                            <p className="mt-1 text-lg font-medium text-gray-800">Attending Doctor: {request.doctor}</p>
                        </p>
                        
                    </li>
                ))}



            </ul>
        </article>
    )
}
RequestList.propTypes = {
    requests: PropTypes.array.isRequired
}
export default RequestList