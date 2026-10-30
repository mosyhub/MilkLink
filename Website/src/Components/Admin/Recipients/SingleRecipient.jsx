import React, { useEffect } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'
import { getPatientDetails } from '../../../redux/actions/recipientActions'
import { Typography } from '@material-tailwind/react'
import { ArrowLongLeftIcon } from '@heroicons/react/24/solid'
import { formatDate, sortRequest } from '../../../utils/helper'
import { createColumnHelper } from '@tanstack/react-table'
import DataTable from '../../DataTables/tanstack/DataTable'
import { useBreadcrumb } from '../../Breadcrumb/BreadcrumbContext'
const SingleRecipient = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const { id } = useParams();
    const dispatch = useDispatch();
    const { patientDetails } = useSelector((state) => state.recipients);

    useEffect(() => {
        dispatch(getPatientDetails(id));
    }, [dispatch, id])

    useEffect(() => {
        if (patientDetails) {
            console.log("patient: ", sortRequest(patientDetails.requested));
        }
    }, [patientDetails])

    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => formatDate(row.date), {
            id: 'date',
            header: 'Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.volumeRequested.volume, {
            id: 'volume',
            header: 'Volume Requested',
            cell: info => `${info.getValue()} ml`,
        }),
        columnHelper.accessor(row => row.volumeRequested.days, {
            id: 'days',
            header: 'Days',
            cell: info => `${info.getValue()} ml`,
        }),
        columnHelper.accessor(row => row.hospital === "Taguig-Pateros District Hospital" ? 'TPDH' : row.hospital, {
            id: 'hospital',
            header: 'Hospital',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.status, {
            id: 'status',
            header: 'Status',
            cell: info => info.getValue(),
        }),

    ];
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Recipients", path: "/dashboard/recipients" },
            { name: "Profile" }
        ])
    }, [])
    return (
        <div className="relative w-full h-full">
            <Link to="/dashboard/recipients" className="absolute top-4 left-4">
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>
            <div className="h-[calc(10vh)] bg-secondary w-full p-4">
                <Typography variant="h3" className="text-center mb-4 text-white font-parkinsans">Patient Information</Typography>
            </div>
            <div className="flex flex-col gap-8 p-4">
                <div className="flex h-[calc(100vh-14rem)] items-start justify-center gap-4">
                    <div className="w-full h-full flex flex-col overflow-y-auto gap-4 p-4 border border-gray-600 rounded-lg">
                        <Typography color="black" variant="h1" className="text-center">{patientDetails && patientDetails.name}</Typography>
                        <div className="flow-root">
                            <dl className="-my-3 divide-y divide-gray-100 text-lg">
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Patient Type</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.patientType}</dd>
                                </div>
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Age:</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.age} kg</dd>
                                </div>
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Age of Gestation:</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.aog} weeks</dd>
                                </div>
                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Address</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.home_address && `${patientDetails.home_address.street} ${patientDetails.home_address.brgy} ${patientDetails.home_address.city}`}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Phone</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.phone}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Mother&apos;s name</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.motherName}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Staff in-charge:</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && patientDetails.staff && patientDetails.staff.name && `${patientDetails.staff.name.first} ${patientDetails.staff.name.middle} ${patientDetails.staff.name.last}`}</dd>
                                </div>

                                <div className="grid grid-cols-1 gap-1 py-3 even:bg-gray-50 sm:grid-cols-3 sm:gap-4">
                                    <dt className="font-medium text-gray-900">Date admitted:</dt>
                                    <dd className="text-gray-700 sm:col-span-2 text-right">{patientDetails && formatDate(patientDetails.admissionDate)}</dd>
                                </div>


                            </dl>
                        </div>
                    </div>
                    <div className="w-full h-full flex flex-col items-center justify-center gap-4 p-4 border border-gray-600 rounded-lg">
                        <DataTable columns={columns} data={sortRequest(patientDetails.requested)} pageSize={5} height="h-full" />
                    </div>
                </div>
            </div>
        </div>
    )
}

export default SingleRecipient