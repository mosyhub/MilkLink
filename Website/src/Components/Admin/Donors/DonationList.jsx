import React from 'react'
import { formatDate } from '../../../utils/helper'
import { Typography } from '@material-tailwind/react'
import PropTypes from 'prop-types'
const DonationList = ({ donations }) => {

    return (
        <article className="rounded-xl w-full border border-gray-70 p-4">
            <div className="flex items-center gap-4">
                <Typography color="black" variant="h2">Donation History</Typography>
            </div>

            <ul className="mt-4 space-y-2">
                {donations.map((donation) => (
                    <div key={donation._id}>
                        {donation.donationType === "Public" ? <li>
                            <p className="flex flex-col h-full rounded-lg border border-gray-500 p-4">
                                <strong className="font-medium text-secondary">{donation.milkLettingEvent?.activity}</strong>
                                <strong className="font-medium text-black">Date: {formatDate(donation.milkLettingEvent?.actDetails.date)}</strong>
                                <p className="mt-1 text-xs font-medium text-gray-800">Total Volume: {donation.totalVolume} mL</p>
                                <p className="mt-1 text-xs font-medium text-gray-800">Donation Type: {donation.donationType}</p>
                            </p>
                        </li> :
                            <li>
                                <p className="block h-full rounded-lg border border-gray-500 p-4">
                                    <strong className="font-medium text-black">Date: {formatDate(donation.schedule.dates)}</strong>
                                    <p className="mt-1 text-xs font-medium text-gray-800">Total Volume: {donation.schedule.totalVolume} mL</p>
                                    <p className="mt-1 text-xs font-medium text-gray-800">Donation Type: {donation.donationType}</p>
                                </p>
                            </li>}

                    </div>
                ))}



            </ul>
        </article>
    )
}
DonationList.propTypes = {
    donations: PropTypes.array.isRequired
}
export default DonationList