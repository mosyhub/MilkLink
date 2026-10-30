import React, { useState, useEffect } from 'react'
import { Button, Input, Select, Option, IconButton } from '@material-tailwind/react'
import { useDispatch, useSelector } from 'react-redux'
import { Link } from 'react-router-dom'
import { MagnifyingGlassIcon } from '@heroicons/react/24/solid'
import { getAllCollections } from '../../../../redux/actions/collectionActions'
import { EyeIcon } from 'lucide-react'
import { createColumnHelper } from '@tanstack/react-table'
import { formatDate } from '../../../../utils/helper'
import DataTable from '../../../../Components/DataTables/tanstack/DataTable'
import { useBreadcrumb } from '../../../../Components/Breadcrumb/BreadcrumbContext'
import PropTypes from 'prop-types'
function ActionsCell({ row }) {
    const { _id, collectionType, status, pubDetails, privDetails } = row.original;
    return (
        <div className="flex gap-2">
            <Link to={`/dashboard/collections/details/${pubDetails?._id || privDetails?._id}`} state={{ type: collectionType, collectionId: _id, status: status }} className="text-blue-500">
                <IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton>
            </Link>
        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
}
const CollectionsTable = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch()
    const { collections } = useSelector(state => state.collections)

    const [search, setSearch] = useState('');
    const [type, setType] = useState('');

    const handleType = (value) => {
        setType(value);
    }
    const handleReset = () => {
        setSearch('');
        setType('');
    }

    const collectionTypes = [
        "Public",
        "Private",
    ]


    const handleTextChange = (e) => {
        setSearch(e.target.value);
    }
    const handleSubmit = () => {

        dispatch(getAllCollections({ search: search }));
    }

    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.pubDetails?.activity || `${row.privDetails?.donorDetails.donor.user.name.first} ${row.privDetails?.donorDetails.donor.user.name.last}`, {
            id: 'activity',
            header: 'Activity Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => `${formatDate(row.collectionDate)}`, {
            id: 'collectionDate',
            header: 'Collection Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.collectionType, {
            id: 'collectionType',
            header: 'Collection Type',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.status, {
            id: 'status',
            header: 'Status',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (<ActionsCell row={row} />),
        }),
    ];
    useEffect(() => {
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Collections' }
        ])
    }, [])
    useEffect(() => {
        dispatch(getAllCollections({ search: search, type: type }))
    }, [dispatch, search, type])
    return (
        <div className="p-4 flex flex-col gap-4">
            <div className="flex flex-col lg:flex-row justify-start items-center gap-4 mt-4">
                <div className="flex gap-4 items-center justify-center">
                    {/* Search */}
                    <div className="relative flex w-full gap-2 md:w-max">
                        <Input
                            type="search"
                            color="gray"
                            label="Search for collections..."
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
                        <Select label="Filter by Collection Type" color="pink" variant="standard" value={type} onChange={(value) => handleType(value)}>
                            {collectionTypes.map((collectionType) => (
                                <Option key={collectionType} value={collectionType}>{collectionType}</Option>
                            ))}
                        </Select>
                    </div>
                </div>
            </div>

            <DataTable data={collections} columns={columns} pageSize={10}/>
        </div>
    )
}

export default CollectionsTable