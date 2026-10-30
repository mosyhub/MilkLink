import { Button } from '@material-tailwind/react'
import React from 'react'
import { Link } from 'react-router-dom'
import PropTypes from 'prop-types'
const RecipientCards = ({ recipients }) => {
    return (

        <div
            className="profile-card w-[300px] border border-secondary rounded-md overflow-hidden  relative cursor-pointer snap-start shrink-0 bg-white flex flex-col items-center justify-center gap-3 transition-all duration-300 group p-8"
        >

            <div className="headings *:text-center *:leading-4">
                <p className="text-xl font-varela font-semibold text-[#434955] mb-1">{recipients.name}</p>
                <p className="text-sm font-varela font-semibold text-[#434955]">{recipients.patientType}</p>
            </div>
            <div className="w-full items-center flex">
                <ul
                    className="flex flex-col items-start gap-2 has-[:last]:border-b-0 *:inline-flex *:gap-2 *:items-center *:justify-center *:border-b-[1.5px] *:border-b-stone-700 *:border-dotted *:text-xs *:font-semibold *:text-[#434955] pb-3"
                >
                    <li>
                        <svg
                            id="phone"
                            viewBox="0 0 24 24"
                            className="fill-stone-700 group-hover:fill-secondary"
                            height="15"
                            width="15"
                            xmlns="http://www.w3.org/2000/svg"
                        >
                            <path d="M0 0h24v24H0V0z" fill="none"></path>
                            <path
                                d="M19.23 15.26l-2.54-.29c-.61-.07-1.21.14-1.64.57l-1.84 1.84c-2.83-1.44-5.15-3.75-6.59-6.59l1.85-1.85c.43-.43.64-1.03.57-1.64l-.29-2.52c-.12-1.01-.97-1.77-1.99-1.77H5.03c-1.13 0-2.07.94-2 2.07.53 8.54 7.36 15.36 15.89 15.89 1.13.07 2.07-.87 2.07-2v-1.73c.01-1.01-.75-1.86-1.76-1.98z"
                            ></path>
                        </svg>
                        <p>{recipients.phone}</p>
                    </li>

                    <li>
                        <svg
                            id="map"
                            viewBox="0 0 16 16"
                            className="fill-stone-700 group-hover:fill-secondary"
                            height="15"
                            width="15"
                            xmlns="http://www.w3.org/2000/svg"
                        >
                            <path
                                d="M8 0C5.2 0 3 2.2 3 5s4 11 5 11 5-8.2 5-11-2.2-5-5-5zm0 8C6.3 8 5 6.7 5 5s1.3-3 3-3 3 1.3 3 3-1.3 3-3 3z"
                                fill="#444"
                            ></path>
                        </svg>
                        <p>{`${recipients.home_address?.street}, ${recipients.home_address?.brgy}, ${recipients.home_address?.city}`}</p>
                    </li>
                    
                    <li>
                        <svg xmlns="http://www.w3.org/2000/svg" height="15" width="15" className="fill-stone-700 " viewBox="0 0 448 512"><path d="M224 0a80 80 0 1 1 0 160A80 80 0 1 1 224 0zM436.8 382.8L373.5 462c-16.6 20.7-46.8 24.1-67.5 7.5c-17.6-14.1-22.7-38.1-13.5-57.7l-.8-.1c-38.9-5.6-74.3-25.1-99.7-54.8l0-36.8c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 48c0 .8 0 1.6 .1 2.4l101.4 50.7c23.7 11.9 33.3 40.7 21.5 64.4s-40.7 33.3-64.4 21.5L27.2 427.3c-1.1-.5-2.2-1.1-3.3-1.7c-4.9-2.8-9.2-6.4-12.6-10.6c-4.6-5.4-7.8-11.7-9.6-18.4c-3.3-12-1.9-25.2 4.8-36.6c.6-1.1 1.3-2.2 2-3.2L75.6 256.1c26.7-40.1 71.7-64.1 119.8-64.1l75.2 0c46.5 0 90.1 22.5 117.2 60.3l50.7 70.9c2.2 3 4 6.1 5.5 9.4c2.9 6.7 4.3 13.8 4 20.8c-.3 10.6-4.2 21-11.2 29.4zM320 332a44 44 0 1 0 -88 0 44 44 0 1 0 88 0z" /></svg>
                        <p>{recipients.motherName}</p>
                    </li>
                    <li>Requests: {recipients.requested.length}</li>
                </ul>
            </div>
            <Link to={`/dashboard/recipient/${recipients._id}`} className="w-full"><Button className="w-full bg-secondary group-hover:transition-all group-hover:duration-300 transition-all duration-300">See information</Button></Link>


        </div>

    )
}
RecipientCards.propTypes = {
    recipients: PropTypes.object.isRequired
}
export default RecipientCards