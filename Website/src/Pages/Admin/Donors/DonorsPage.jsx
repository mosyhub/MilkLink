import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getDonors } from '../../../redux/actions/donorActions'
import { Input, Button, IconButton, Select, Option } from '@material-tailwind/react'
import { MagnifyingGlassIcon } from '@heroicons/react/24/solid'
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
            <Link to={`/dashboard/donors/${id}`}>
                <IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton>
            </Link>
        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
}
const DonorsPage = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const { donors, pageSize } = useSelector((state) => state.donors);
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

    const donorTypes = [
        "Community",
        "Private",
        "Employee",
        "Network Office/Agency"
    ]


    const handleTextChange = (e) => {
        setSearch(e.target.value);
    }
    const handleSubmit = () => {
        setCurrentPage(0);
        dispatch(getDonors({ search: search }));
    }

    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => `${row.user.name.first} ${row.user.name.last}`, {
            id: 'name',
            header: 'Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.user.email, {
            id: 'email',
            header: 'Email',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => `${row.home_address.street}, ${row.home_address.brgy}, ${row.home_address.city}`, {
            id: 'address',
            header: 'Address',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.user.phone, {
            id: 'phone',
            header: 'Phone',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (
                <ActionsCell row={row} />
            ),
        }),
    ];
    useEffect(() => {
        dispatch(getDonors({ search: search, brgy: brgy, type: type, page: currentPage + 1, pageSize: pageSize }))
            .unwrap()
            .then((data) => console.log('Donors fetched:', data))
            .catch((err) => console.error('Error fetching donors:', err));
    }, [dispatch, search, currentPage, brgy, type])
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Donors", path: "/dashboard/donors" }
        ])
    }, [])
    return (
        <div className="p-4 flex flex-col gap-4">
            <div className="flex flex-col lg:flex-row justify-start items-center gap-4 mt-4">
                <div className="flex gap-4 items-center justify-center">
                    {/* Search */}
                    <div className="relative flex w-full gap-2 md:w-max">
                        <Input
                            type="search"
                            color="gray"
                            label="Search for donors..."
                            className="pr-10"
                            onChange={handleTextChange}
                            containerProps={{
                                className: "min-w-[288px]",
                            }}
                        />
                        <MagnifyingGlassIcon className="h-8 w-8 !absolute right-1 top-1 rounded text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer" onClick={handleSubmit} />

                    </div>
                    {/* Delete Filter */}
                    <div className="w-full flex justify-center items-center gap-4">
                        <Button color="pink" onClick={handleReset} className='w-max'>Delete filters</Button>
                    </div>
                </div>
                {/* Filter */}
                <div className="flex gap-4 items-center justify-center flex-wrap">
                    <div className="w-max">
                        <Select label="Filter by Barangay" color="pink" variant="standard" value={brgy} onChange={(value) => handleBrgy(value)}>
                            {locations.map((location) => (
                                <Option key={location} value={location}>{location}</Option>
                            ))}
                        </Select>
                    </div>
                    <div className="w-max">
                        <Select label="Filter by Donor Type" color="pink" variant="standard" value={type} onChange={(value) => handleType(value)}>
                            {donorTypes.map((donorType) => (
                                <Option key={donorType} value={donorType}>{donorType}</Option>
                            ))}
                        </Select>
                    </div>
                </div>
            </div>
            <DataTable data={donors} columns={columns} pageSize={15}/>
        </div>
    )
}

export default DonorsPage