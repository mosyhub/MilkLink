import React, { useState, useEffect } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'
import { getSingleDonor } from '../../../redux/actions/donorActions'
import { Typography } from '@material-tailwind/react'
import { ArrowLongLeftIcon } from '@heroicons/react/24/solid'
import { donationHistoryChart, formatDate, sortDonation } from '../../../utils/helper'
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { createColumnHelper } from '@tanstack/react-table'
import DataTable from '../../DataTables/tanstack/DataTable'
import { useBreadcrumb } from '../../Breadcrumb/BreadcrumbContext'
const SingleDonor = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const { id } = useParams();
    const dispatch = useDispatch();
    const { donorDetails } = useSelector((state) => state.donors);
    const [chartData, setChartData] = useState([]);
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Donors", path: "/dashboard/donors" },
            { name: "Profile" }
        ])
    }, [donorDetails])
    useEffect(() => {
        dispatch(getSingleDonor(id));
    }, [dispatch, id])

    useEffect(() => {
        if (
            donorDetails &&
            Array.isArray(donorDetails.donations) &&
            donorDetails.donations.length > 0
        ) {
            const chart = donationHistoryChart(donorDetails.donations);
            setChartData(chart);
        }
        else {
            setChartData([]);
        }
    }, [donorDetails]);

    useEffect(() => {
        console.log("chart: ", chartData);
    }, [chartData])

    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.donationType === "Public" ? row.milkLettingEvent.activity : "Scheduled Pick-up", {
            id: 'activity',
            header: 'Activity',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.donationType === "Public" ? formatDate(row.milkLettingEvent.actDetails.date, "short") : formatDate(row.schedule.dates, "short"), {
            id: 'date',
            header: 'Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.donationType === "Public" ? row.totalVolume : row.schedule.totalVolume, {
            id: 'volume',
            header: 'Total Volume',
            cell: info => `${info.getValue()} ml`,
        }),
        columnHelper.accessor(row => row.donationType, {
            id: 'donationType',
            header: 'Donation Type',
            cell: info => info.getValue(),
        }),

    ];

    useEffect(() => {
        if (donorDetails && donorDetails.donations && donorDetails.donations.length > 0) {
            console.log(sortDonation(donorDetails.donations));
        }
    }, [donorDetails])
    return (
        <div className="relative w-full h-full">
            <Link to="/dashboard/donors" className="absolute top-4 left-4">
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>
            <div className="h-[calc(30vh)] bg-secondary w-full p-4">
                <Typography variant="h3" className="text-center mb-4 text-white font-parkinsans">Donation History</Typography>
                <ResponsiveContainer width="100%" height="75%">
                    <AreaChart
                        width={500}
                        height={400}
                        data={chartData}
                        margin={{
                            top: 10,
                            right: 30,
                            left: 0,
                            bottom: 0,
                        }}
                    >
                        <CartesianGrid stroke="rgba(255, 255, 255, 0.2)" strokeDasharray="3 3" />
                        <XAxis
                            dataKey="name"
                            stroke="white"
                            tick={{ fill: "white" }}
                            axisLine={{ stroke: "white" }}
                        />
                        <YAxis
                            stroke="white"
                            tick={{ fill: "white" }}
                            axisLine={{ stroke: "white" }}
                        />
                        <Tooltip
                            contentStyle={{ backgroundColor: '#333', borderRadius: '8px', border: 'none' }}
                            labelStyle={{ color: 'white' }}
                            itemStyle={{ color: 'white' }}
                            formatter={(value) => [`${value} ml`, "Total Volume"]}
                            labelFormatter={(label) => `Date: ${label}`}
                        />
                        <Area type="monotone" dataKey="totalVolume" stroke="#FFF" fill="#fff" />
                    </AreaChart>
                </ResponsiveContainer>

            </div>
            <div className="flex flex-col gap-8 p-4">
                <div className="flex h-max lg:h-[calc(100vh-18rem)] items-start justify-center gap-4">
                    {/* Donor Information */}
                    <div className="w-full h-full flex flex-col gap-4 p-4 border border-gray-600 rounded-lg overflow-y-auto">
                        <Typography color="black" variant="h1">{donorDetails && donorDetails.user && donorDetails.user.name && `${donorDetails.user.name.first} ${donorDetails.user.name.middle} ${donorDetails.user.name.last}`}</Typography>
                        <div className="flow-root">
                            <dl className="-my-3 divide-y divide-gray-100 text-lg">
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Donor Type</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.donorType}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Address</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.home_address && `${donorDetails.home_address.street}, ${donorDetails.home_address.brgy}, ${donorDetails.home_address.city}`}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Phone</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.user && donorDetails.user.phone}</dd>
                                </div>
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Email</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.user && donorDetails.user.email}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Birthday</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && formatDate(donorDetails.birthday, "short")}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Age</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.age}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Occupation</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.occupation}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Eligibility</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails ? donorDetails.eligibility : '--'}</dd>
                                </div>
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Last Interview Form Submission</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails ? formatDate(donorDetails.lastSubmissionDate, "short") : '--'}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Date tested:</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">
                                        {donorDetails && donorDetails.dateTested ? formatDate(donorDetails.dateTested, "short") : '--'}
                                    </dd>
                                </div>
                            </dl>
                        </div>
                    </div>


                    <div className="flex h-max lg:h-[calc(100vh-18rem)] flex-col w-full gap-4">
                        {/* Child information */}
                        <div className="w-full h-full flex flex-col items-center justify-center gap-4 p-4 border border-gray-600 rounded-lg ">
                            <Typography color="black" variant="h1">Child Information</Typography>
                            <div className="flow-root">
                                <dl className="-my-3 divide-y divide-gray-100 text-lg">
                                    <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                        <dt className="font-medium text-gray-900">Name</dt>
                                        <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.children && donorDetails.children.length > 0 && donorDetails.children[0].name}</dd>
                                    </div>

                                    <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                        <dt className="font-medium text-gray-900">Age</dt>
                                        <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.children && donorDetails.children.length > 0 && donorDetails.children[0].age.value} {donorDetails && donorDetails.children && donorDetails.children.length > 0 && donorDetails.children[0].age.unit}</dd>
                                    </div>
                                    <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                        <dt className="font-medium text-gray-900">Age of Gestation (AOG)</dt>
                                        <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.children && donorDetails.children.length > 0 && donorDetails.children[0].aog} weeks</dd>
                                    </div>
                                    <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                        <dt className="font-medium text-gray-900">Birth Weight</dt>
                                        <dd className="text-gray-700 sm:col-span-2 text-right">{donorDetails && donorDetails.children && donorDetails.children.length > 0 && donorDetails.children[0].birth_weight} kg</dd>
                                    </div>
                                </dl>
                            </div>
                        </div>
                        {/* Donation History */}
                        <div className="w-full h-full flex flex-col items-center justify-center gap-4 p-4 border border-gray-600 rounded-lg">
                            <DataTable columns={columns} data={sortDonation(donorDetails.donations)} pageSize={5} height="h-full" />
                        </div>
                    </div>

                </div>
            </div>
        </div >
    )
}

export default SingleDonor