import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getRecipients } from '../../../redux/actions/recipientActions'
import { Input, Button, IconButton, Select, Option } from '@material-tailwind/react'
import { MagnifyingGlassIcon } from '@heroicons/react/24/solid'
import { getUser } from '../../../utils/helper'
import { createColumnHelper } from '@tanstack/react-table'
import DataTable from '../../../Components/DataTables/tanstack/DataTable'
import { Link } from 'react-router-dom'
import { EyeIcon } from 'lucide-react'
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext'
import PropTypes from 'prop-types'

function ActionsCell({ row }) {
    const id = row.original._id
    return (
        <div className="flex gap-2">
            <Link to={`/dashboard/recipient/${id}`}>
                <IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton>
            </Link>
        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
}
const RecipientPage = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const { recipients, pageSize } = useSelector((state) => state.recipients);
    const [search, setSearch] = useState('');
    const [currentPage, setCurrentPage] = useState(0);
    const [brgy, setBrgy] = useState('');
    const [type, setType] = useState('');

    const handleBrgy = (value) => {
        setBrgy(value);
    }
    const handleType = (value) => {
        setType(value);
    }
    const handleReset = () => {
        setSearch('');
        setBrgy('');
        setType('');
    }
    const locations = [
        "Bagumbayan",
        "Bambang",
        "Calzada",
        "Cembo",
        "Central Bicutan",
        "Central Signal Village",
        "Comembo",
        "East Rembo",
        "Fort Bonifacio",
        "Hagonoy",
        "Ibayo Tipas",
        "Katuparan",
        "Ligid Tipas",
        "Lower Bicutan",
        "Maharlika Village",
        "Miguel",
        "Napindan",
        "New Lower Bicutan",
        "North Daang Hari",
        "North Signal Village",
        "Northside",
        "Palingon",
        "Pembo",
        "Pinagsama",
        "Pitogo",
        "Rizal",
        "Santa Ana",
        "South Cembo",
        "South Daang Hari",
        "South Signal Village",
        "Southside",
        "Tanyag",
        "Tuktukan",
        "Upper Bicutan",
        "Ususan",
        "Wawa",
        "West Rembo",
        "Western Bicutan"
    ];

    const patientTypes = [
        "Inpatient",
        "Outpatient"
    ]


    const handleTextChange = (e) => {
        setSearch(e.target.value);
    }
    const handleSubmit = () => {
        setCurrentPage(0);
        dispatch(getRecipients({ search: search }));
    }
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.name, {
            id: 'name',
            header: 'Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => `${row.home_address.street}, ${row.home_address.brgy}, ${row.home_address.city}`, {
            id: 'address',
            header: 'Address',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.motherName, {
            id: 'motherName',
            header: 'Parent/Guardian Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.phone, {
            id: 'phone',
            header: 'Phone',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.patientType, {
            id: 'patientType',
            header: 'Patient Type',
            cell: info => info.getValue(),
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (<ActionsCell row={row} />),
        }),
    ];
    useEffect(() => {
        dispatch(getRecipients({ search: search, brgy: brgy, type: type, page: currentPage + 1, pageSize: pageSize }))
            .unwrap()
            .then((data) => console.log('Recipients fetched:', data))
            .catch((err) => console.error('Error fetching Recipients:', err));
    }, [dispatch, search, currentPage, brgy, type])
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Recipients", path: "/dashboard/recipients" }
        ])
    }, [])
    useEffect(() => {
        // Load the Tally embed script
        const script = document.createElement("script");
        script.src = "https://tally.so/widgets/embed.js";
        script.async = true;
        document.body.appendChild(script);

        // Cleanup the script when the component is unmounted
        return () => {
            document.body.removeChild(script);
        };
    }, [])
    const handleOpenTallyForm = () => {
        const staff = getUser()._id // replace with your actual variable
        const url = `https://tally.so/r/mOrazY?staffId=${encodeURIComponent(staff)}`;
        window.open(url, "_blank"); // or open in an iframe/modal if needed
    };

    return (
        <div className="p-4 flex flex-col h-[calc(100vh-2rem)] gap-4">
            <div className="flex flex-col lg:flex-row justify-between items-center gap-4">
                <div className="flex flex-col lg:flex-row justify-start items-center gap-4">
                    <div className="flex items-center gap-4 mt-4">
                        {/* Search */}
                        <div className="relative flex w-full gap-2 md:w-max">
                            <Input
                                type="search"
                                color="gray"
                                label="Search for patients..."
                                className="pr-10"
                                onChange={handleTextChange}
                                containerProps={{
                                    className: "min-w-[288px]",
                                }}
                            />
                            <MagnifyingGlassIcon className="h-8 w-8 !absolute right-1 top-1 rounded text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer" onClick={handleSubmit} />

                        </div>
                        {/* Delete Filter */}
                        <div className="w-full">
                            <Button color="pink" onClick={handleReset} className='w-max'>Delete filters</Button>
                        </div>
                    </div>
                    {/* Filters */}
                    <div className="flex items-center gap-4 justify-center flex-wrap">
                        <div className="w-max">
                            <Select label="Filter by Barangay" color="pink" variant="standard" value={brgy} onChange={(value) => handleBrgy(value)}>
                                {locations.map((location) => (
                                    <Option key={location} value={location}>{location}</Option>
                                ))}
                            </Select>
                        </div>
                        <div className="w-max">
                            <Select label="Filter by Patient Type" color="pink" variant="standard" value={type} onChange={(value) => handleType(value)}>
                                {patientTypes.map((donorType) => (
                                    <Option key={donorType} value={donorType}>{donorType}</Option>
                                ))}
                            </Select>
                        </div>
                    </div>
                </div>

                <div>
                    <Button color="pink" onClick={handleOpenTallyForm}>Add New Patient</Button>
                </div>
            </div>
            <DataTable data={recipients} columns={columns} pageSize={15} />
        </div>
    )
}

export default RecipientPage